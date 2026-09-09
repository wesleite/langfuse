from dotenv import load_dotenv
from langfuse import get_client

# Carrega as variáveis do arquivo .env
load_dotenv()

# Obtém a instância do cliente Langfuse
langfuse = get_client()

# Cria o span e trace utilizando o gerenciador de contexto moderno
with langfuse.start_as_current_observation(as_type="span", name="teste-langfuse") as span:
    span.update(
        input={"mensagem": "Olá Kubernetes"},
        output={"status": "sucesso"}
    )

# Força o envio imediato dos dados para o cluster
langfuse.flush()
print("Trace enviado com sucesso!")