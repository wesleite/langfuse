from dotenv import load_dotenv
from langfuse import get_client

# Carrega as variáveis de ambiente do .env
load_dotenv()

langfuse = get_client()

# Cria um span usando um gerenciador de contexto
with langfuse.start_as_current_observation(as_type="span", name="process-item") as span:
    # Sua lógica de processamento aqui
    span.update(output="Processing complete")

# Cria uma geração aninhada para uma chamada de LLM
with langfuse.start_as_current_observation(as_type="generation", name="llm-call") as generation:
    # Sua lógica de chamada de LLM aqui
    generation.update(output="Generated response")

# Todos os spans são fechados automaticamente ao sair dos blocos de contexto

# Força o envio imediato dos eventos (recomendado em aplicações de curta duração)
langfuse.flush()