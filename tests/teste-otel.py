from dotenv import load_dotenv
from langfuse import get_client

# Carrega as configurações do arquivo .env (LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY, LANGFUSE_BASE_URL)
load_dotenv()

# Inicializa o cliente unificado do Langfuse
langfuse = get_client()


def executar_fluxo_llm(pergunta_usuario: str):
    # Span raiz estruturando o fluxo de execução principal da aplicação
    with langfuse.start_as_current_observation(as_type="span", name="fluxo-principal-rag") as span:
        span.update(input={"pergunta": pergunta_usuario})

        # Span secundário para rastrear etapas auxiliares (ex: busca em base vetorial / retrieval)
        with langfuse.start_as_current_observation(as_type="span", name="recuperacao-documentos") as retrieve_span:
            retrieve_span.update(input={"query": pergunta_usuario})
            contexto_recuperado = "Informações extraídas da base de conhecimento interna sobre o Langfuse."
            retrieve_span.update(output={"documentos_encontrados": [contexto_recuperado]})

        # Geração (Chamada de LLM) vinculada ao contexto ativo da observação
        with langfuse.start_as_current_observation(as_type="generation", name="geracao-resposta-llm") as generation:
            generation.update(
                model="gpt-4o",
                model_parameters={"temperature": 0.3, "max_tokens": 300},
                input=[
                    {"role": "system", "content": "Você é um assistente técnico."},
                    {"role": "user", "content": f"Contexto: {contexto_recuperado}\n\nPergunta: {pergunta_usuario}"}
                ]
            )

            # Simulação da resposta gerada pelo modelo de IA
            resposta_modelo = "O Langfuse utiliza SDKs modernos para capturar spans, gerações e custos de forma assíncrona."

            # Atualiza a geração com a saída e métricas de consumo de tokens (usage)
            generation.update(
                output=resposta_modelo,
                usage={
                    "input": 52,
                    "output": 24,
                    "total": 76
                }
            )

        span.update(output={"resposta_final": resposta_modelo})


if __name__ == "__main__":
    executar_fluxo_llm("Como instrumentar o código com o SDK do Langfuse?")

    # Assegura que o lote de spans acumulados seja enviado imediatamente para o servidor local
    langfuse.flush()
    print("Instrumentação executada e traces transmitidos com sucesso!")