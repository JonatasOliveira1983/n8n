FROM docker.n8n.io/n8nio/n8n

# Permite conexões externas
ENV N8N_HOST=0.0.0.0
# Define a URL de produção para webhooks
ENV WEBHOOK_URL=https://n8n-production-8e2d4.up.railway.app
# Informa ao Railway qual porta o contêiner estará escutando
EXPOSE 5678

CMD ["n8n"]
