import Flutter
import UIKit
import Metal

public class EdgeMcpFlutterPlugin: NSObject, FlutterPlugin {
    
    // MARK: - Real MLC-LLM Integration
    private var mlcEngine: MLCLlamaEngine?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "edge_mcp_flutter", binaryMessenger: registrar.messenger())
        let instance = EdgeMcpFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            Task {
                await handleInitialize(result)
            }
        case "generateText":
            Task {
                await handleGenerateText(call, result)
            }
        case "getDeviceCapabilities":
            handleGetDeviceCapabilities(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Real MLC-LLM Methods
    
    private func handleInitialize(_ result: @escaping FlutterResult) async {
        print("🚀 HandleInitializeModel called")
        
        do {
            // Initialize the real MLC-LLM engine
            if mlcEngine == nil {
                mlcEngine = MLCLlamaEngine()
            }
            
            try await mlcEngine?.initialize()
            
            let response: [String: Any] = [
                "success": true,
                "model": "TinyLlama-1.1B-Chat-v1.0-q4f16_1-MLC",
                "memoryUsage": 716240000, // 716.24 MB as compiled
                "capabilities": getDeviceCapabilities()
            ]
            
            print("✅ Real MLC-LLM initialization completed successfully")
            result(response)
            
        } catch {
            print("❌ Model initialization failed: \(error)")
            result(FlutterError(
                code: "INITIALIZATION_FAILED",
                message: "Failed to initialize EdgeLlmIOS: \(error)",
                details: nil
            ))
        }
    }
    
    private func handleGenerateText(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) async {
        print("🌉 NativeEdgeLlmBridge.generate called")
        
        guard let args = call.arguments as? [String: Any],
              let prompt = args["prompt"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing prompt", details: nil))
            return
        }
        
        let maxTokens = args["maxTokens"] as? Int ?? 2048
        let temperature = args["temperature"] as? Float ?? 0.7
        
        print("📝 Prompt: \"\(prompt)\"")
        print("⚙️ System: \"\(args["system"] ?? "null")\"")
        print("🎛️ MaxTokens: \(maxTokens), Temperature: \(temperature)")
        
        guard let engine = mlcEngine else {
            result(FlutterError(code: "ENGINE_NOT_INITIALIZED", message: "MLC engine not initialized", details: nil))
            return
        }
        
        do {
            // Generate using real MLC-LLM
            let tokens = try await engine.generate(
                prompt: prompt,
                maxTokens: maxTokens,
                temperature: temperature
            )
            
            print("✅ Native method call completed")
            print("🔍 Result type: Generated \(tokens.count) tokens")
            
            let response: [String: Any] = [
                "tokens": tokens,
                "usage": [
                    "promptTokens": prompt.components(separatedBy: .whitespacesAndNewlines).count,
                    "completionTokens": tokens.count,
                    "totalTokens": tokens.count + prompt.components(separatedBy: .whitespacesAndNewlines).count
                ],
                "model": "TinyLlama-1.1B-MLC"
            ]
            
            print("📊 Result: \(response)")
            result(response)
            
        } catch {
            print("❌ Generation failed: \(error)")
            result(FlutterError(
                code: "GENERATION_FAILED",
                message: "Text generation failed: \(error)",
                details: nil
            ))
        }
    }
    
    private func handleGetDeviceCapabilities(_ result: @escaping FlutterResult) {
        let capabilities = getDeviceCapabilities()
        result(capabilities)
    }
    
    private func getDeviceCapabilities() -> [String: Any] {
        print("🔍 Device Capability Debug:")
        
        let device = MTLCreateSystemDefaultDevice()
        let processInfo = ProcessInfo.processInfo
        
        // Get device model
        var systemInfo = utsname()
        uname(&systemInfo)
        let deviceModel = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        
        // Check Neural Engine availability (iOS 13+)
        let hasNeuralEngine = device?.supportsFamily(.common3) ?? false
        
        // Get memory info
        let totalMemory = Double(processInfo.physicalMemory) / (1024 * 1024 * 1024) // GB
        let availableMemory = totalMemory // Simplified - should use vm_stat for accuracy
        
        let capabilities: [String: Any] = [
            "deviceModel": deviceModel,
            "hasNeuralEngine": hasNeuralEngine,
            "totalMemoryGB": totalMemory,
            "availableMemoryGB": availableMemory,
            "metalSupport": device != nil,
            "metalDeviceName": device?.name ?? "No Metal device",
            "isOptimalDevice": totalMemory >= 4.0 && hasNeuralEngine,
            "performanceTier": getPerformanceTier(totalMemory: totalMemory),
            "estimatedTokensPerSecond": estimateTokensPerSecond(deviceModel: deviceModel),
            "estimatedFirstTokenLatency": 150, // ms
            "maxRecommendedContextLength": 2048
        ]
        
        print("📱 Device Model: \(deviceModel)")
        print("🧠 Neural Engine: \(hasNeuralEngine)")
        print("💾 Total Memory: \(Int(totalMemory)) GB")
        print("💾 Available Memory: \(Int(availableMemory)) GB")
        print("🚀 Metal Support: \(device != nil)")
        print("⚡ Optimal Device: \(capabilities["isOptimalDevice"] as? Bool ?? false)")
        
        return capabilities
    }
    
    private func getPerformanceTier(totalMemory: Double) -> String {
        if totalMemory >= 8.0 {
            return "high"
        } else if totalMemory >= 4.0 {
            return "medium"
        } else {
            return "low"
        }
    }
    
    private func estimateTokensPerSecond(deviceModel: String) -> Double {
        // Rough estimates based on device capabilities
        if deviceModel.contains("iPhone16") || deviceModel.contains("iPhone17") { // A17/A18 Pro
            return 25.0
        } else if deviceModel.contains("iPhone15") { // A16/A17
            return 20.0
        } else if deviceModel.contains("iPhone14") || deviceModel.contains("iPhone13") { // A15/A16
            return 15.0
        } else {
            return 10.0
        }
    }
} 