#ifndef MLCBridge_h
#define MLCBridge_h

#ifdef __cplusplus
extern "C" {
#endif

// MLC-LLM C++ Bridge Functions
void* mlc_llm_create_engine(const char* model_path);
int mlc_llm_generate(void* engine, const char* prompt, int max_tokens, float temperature, void (*callback)(const char*));
void mlc_llm_destroy_engine(void* engine);

#ifdef __cplusplus
}
#endif

#endif /* MLCBridge_h */ 