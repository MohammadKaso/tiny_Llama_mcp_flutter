#include "MLCBridge.h"
#include <string>
#include <vector>
#include <memory>
#include <iostream>
#include <functional>
#include <chrono>

// Include TVM FFI headers for real MLC-LLM integration
#include <tvm/runtime/module.h>
#include <tvm/runtime/packed_func.h>
#include <tvm/runtime/registry.h>

using namespace tvm::runtime;

class MLCEngineWrapper {
private:
    std::string model_path_;
    std::function<void(const char*)> token_callback_;
    bool is_initialized_;
    Module json_ffi_engine_;
    PackedFunc init_background_engine_;
    PackedFunc reload_;
    PackedFunc chat_completion_;
    PackedFunc run_background_loop_;
    PackedFunc run_background_stream_back_loop_;
    PackedFunc get_last_error_;

public:
    MLCEngineWrapper(const std::string& model_path) : model_path_(model_path), is_initialized_(false) {
        std::cout << "🔧 Creating REAL MLC Engine with model path: " << model_path << std::endl;
        
        try {
            // Create the real MLC-LLM JSON FFI engine
            const PackedFunc* create_func = Registry::Get("mlc.json_ffi.CreateJSONFFIEngine");
            if (!create_func) {
                throw std::runtime_error("Cannot find mlc.json_ffi.CreateJSONFFIEngine function");
            }
            
            json_ffi_engine_ = (*create_func)();
            
            // Get all the required methods
            init_background_engine_ = json_ffi_engine_->GetFunction("init_background_engine");
            reload_ = json_ffi_engine_->GetFunction("reload");
            chat_completion_ = json_ffi_engine_->GetFunction("chat_completion");
            run_background_loop_ = json_ffi_engine_->GetFunction("run_background_loop");
            run_background_stream_back_loop_ = json_ffi_engine_->GetFunction("run_background_stream_back_loop");
            get_last_error_ = json_ffi_engine_->GetFunction("get_last_error");
            
            // Create streaming callback
            PackedFunc stream_callback = PackedFunc([this](TVMArgs args, TVMRetValue* rv) {
                std::string response_json = args[0].operator std::string();
                // Parse and extract tokens from JSON response
                this->processStreamResponse(response_json);
            });
            
            // Initialize with Metal device (device_type=8 for Metal, device_id=0)
            init_background_engine_(8, 0, stream_callback);
            
            // Create engine configuration for TinyLlama
            std::string engine_config = R"({
                "model": ")" + model_path + R"(",
                "model_lib": "TinyLlama-1.1B-MLC",
                "device": "metal:0",
                "max_num_sequence": 1,
                "max_total_sequence_length": 2048,
                "prefill_chunk_size": 2048,
                "max_history_size": 1
            })";
            
            // Reload the model
            reload_(engine_config);
            
            is_initialized_ = true;
            std::cout << "✅ REAL MLC-LLM engine initialized successfully" << std::endl;
            
        } catch (const std::exception& e) {
            std::cerr << "❌ Failed to initialize REAL MLC engine: " << e.what() << std::endl;
            is_initialized_ = false;
        }
    }
    
    ~MLCEngineWrapper() {
        std::cout << "🗑️ Destroying REAL MLC Engine" << std::endl;
        if (is_initialized_) {
            try {
                PackedFunc exit_loop = json_ffi_engine_->GetFunction("exit_background_loop");
                exit_loop();
            } catch (...) {
                // Ignore cleanup errors
            }
        }
    }
    
    void processStreamResponse(const std::string& response_json) {
        if (!token_callback_) return;
        
        // Parse the JSON response and extract content
        // For now, do basic parsing - in production you'd use a proper JSON parser
        std::cout << "📡 Stream response: " << response_json << std::endl;
        
        // Look for content field in the JSON
        size_t content_pos = response_json.find("\"content\":\"");
        if (content_pos != std::string::npos) {
            size_t start = content_pos + 11; // Length of "\"content\":\""
            size_t end = response_json.find("\"", start);
            if (end != std::string::npos) {
                std::string content = response_json.substr(start, end - start);
                if (!content.empty()) {
                    token_callback_(content.c_str());
                }
            }
        }
    }
    
    int generate(const std::string& prompt, int max_tokens, float temperature, void (*callback)(const char*)) {
        if (!is_initialized_) {
            std::cerr << "❌ REAL Engine not initialized" << std::endl;
            return -1;
        }
        
        std::cout << "🔄 REAL MLC Engine generating for prompt: " << prompt << std::endl;
        
        // Store callback for use in streaming
        token_callback_ = callback;
        
        // Create OpenAI-style chat completion request
        std::string request_json = R"({
            "messages": [
                {
                    "role": "user", 
                    "content": ")" + prompt + R"("
                }
            ],
            "model": "TinyLlama-1.1B-MLC",
            "max_tokens": )" + std::to_string(max_tokens) + R"(,
            "temperature": )" + std::to_string(temperature) + R"(,
            "stream": true
        })";
        
        // Generate unique request ID
        std::string request_id = "req_" + std::to_string(std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
        
        try {
            // Call the REAL MLC-LLM chat completion
            std::cout << "🚀 Calling REAL MLC-LLM chat_completion with request: " << request_json << std::endl;
            bool success = chat_completion_(request_json, request_id);
            
            if (!success) {
                std::string error = get_last_error_();
                std::cerr << "❌ REAL MLC Generation failed: " << error << std::endl;
                return -2;
            }
            
            std::cout << "✅ REAL MLC-LLM generation started successfully" << std::endl;
            return 0;
            
        } catch (const std::exception& e) {
            std::cerr << "❌ REAL Generation failed: " << e.what() << std::endl;
            return -2;
        }
    }
    
    bool isInitialized() const {
        return is_initialized_;
    }
};

extern "C" {

void* mlc_llm_create_engine(const char* model_path) {
    try {
        std::cout << "🚀 Creating REAL MLC-LLM engine (no more fake tokens!)" << std::endl;
        auto* engine = new MLCEngineWrapper(std::string(model_path));
        if (!engine->isInitialized()) {
            delete engine;
            return nullptr;
        }
        return static_cast<void*>(engine);
    } catch (const std::exception& e) {
        std::cerr << "❌ Failed to create REAL MLC engine: " << e.what() << std::endl;
        return nullptr;
    }
}

int mlc_llm_generate(void* engine, const char* prompt, int max_tokens, float temperature, void (*callback)(const char*)) {
    if (!engine || !prompt) {
        return -1;
    }
    
    try {
        std::cout << "🎯 REAL inference requested - NO MORE HARDCODED TOKENS!" << std::endl;
        auto* mlc_engine = static_cast<MLCEngineWrapper*>(engine);
        return mlc_engine->generate(std::string(prompt), max_tokens, temperature, callback);
    } catch (const std::exception& e) {
        std::cerr << "❌ REAL Generation failed: " << e.what() << std::endl;
        return -2;
    }
}

void mlc_llm_destroy_engine(void* engine) {
    if (engine) {
        auto* mlc_engine = static_cast<MLCEngineWrapper*>(engine);
        delete mlc_engine;
    }
}

} 