#!/bin/bash

# Script di test per comunicazione Server-to-Server
# Testa il Client Server (porta 8002) che comunica con l'Inference Server (porta 8001)

CLIENT_SERVER="http://localhost:8002"
INFERENCE_SERVER="http://localhost:8001"
IMAGE_FILE="image.png"

echo "=========================================="
echo "TEST SERVER-TO-SERVER COMMUNICATION"
echo "=========================================="
echo ""

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health check del server client
echo -e "${YELLOW}1. Health Check - Client Server (porta 8002):${NC}"
curl -s "${CLIENT_SERVER}/health" | python3 -m json.tool
echo ""
echo ""

# Test 2: Verifica connessione al server di inferenza
echo -e "${YELLOW}2. Verifica connessione al Inference Server:${NC}"
curl -s "${CLIENT_SERVER}/inference-server-status" | python3 -m json.tool
echo ""
echo ""

# Test 3: Classificazione singola immagine
echo -e "${YELLOW}3. Classificazione immagine (Server-to-Server):${NC}"
if [ -f "$IMAGE_FILE" ]; then
    echo "Invio immagine: $IMAGE_FILE"
    curl -X POST "${CLIENT_SERVER}/classify" \
      -H "accept: application/json" \
      -F "file=@${IMAGE_FILE}" | python3 -m json.tool
    echo ""
else
    echo -e "${RED}ERRORE: File $IMAGE_FILE non trovato!${NC}"
fi
echo ""

# Test 4: Info API
echo -e "${YELLOW}4. Info Client Server:${NC}"
curl -s "${CLIENT_SERVER}/" | python3 -m json.tool
echo ""
echo ""

# Test 5: Confronto diretto con inference server
echo -e "${YELLOW}5. CONFRONTO - Stessa immagine al server di inferenza diretto:${NC}"
if [ -f "$IMAGE_FILE" ]; then
    curl -X POST "${INFERENCE_SERVER}/predict" \
      -H "accept: application/json" \
      -F "file=@${IMAGE_FILE}" | python3 -m json.tool
    echo ""
else
    echo -e "${RED}ERRORE: File $IMAGE_FILE non trovato!${NC}"
fi
echo ""

echo "=========================================="
echo "TEST COMPLETATO"
echo "=========================================="
