#!/bin/bash

# Script per avviare entrambi i server in background

echo "=========================================="
echo "Avvio Server-to-Server Architecture"
echo "=========================================="
echo ""

# Funzione per verificare se una porta è in uso
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "⚠️  Porta $1 già in uso!"
        return 1
    else
        return 0
    fi
}

# Verifica porte
echo "Verifica disponibilità porte..."
if ! check_port 8001; then
    echo "Termina il processo sulla porta 8001 o usa una porta diversa"
    exit 1
fi

if ! check_port 8002; then
    echo "Termina il processo sulla porta 8002 o usa una porta diversa"
    exit 1
fi

echo "✓ Porte disponibili"
echo ""

# Avvia Inference Server
echo "🚀 Avvio Inference Server (porta 8001)..."
uvicorn main:app --host 0.0.0.0 --port 8001 > inference_server.log 2>&1 &
INFERENCE_PID=$!
echo "   PID: $INFERENCE_PID"
echo "   Log: inference_server.log"
sleep 2

# Verifica che sia partito
if ! kill -0 $INFERENCE_PID 2>/dev/null; then
    echo "❌ Errore nell'avvio dell'Inference Server"
    echo "Controlla il file inference_server.log"
    exit 1
fi
echo "✓ Inference Server avviato"
echo ""

# Avvia Client Server
echo "🚀 Avvio Client Server (porta 8002)..."
uvicorn client_server:app --host 0.0.0.0 --port 8002 > client_server.log 2>&1 &
CLIENT_PID=$!
echo "   PID: $CLIENT_PID"
echo "   Log: client_server.log"
sleep 2

# Verifica che sia partito
if ! kill -0 $CLIENT_PID 2>/dev/null; then
    echo "❌ Errore nell'avvio del Client Server"
    echo "Controlla il file client_server.log"
    kill $INFERENCE_PID 2>/dev/null
    exit 1
fi
echo "✓ Client Server avviato"
echo ""

echo "=========================================="
echo "✅ Entrambi i server sono attivi!"
echo "=========================================="
echo ""
echo "📊 Status:"
echo "   Inference Server: http://localhost:8001 (PID: $INFERENCE_PID)"
echo "   Client Server:    http://localhost:8002 (PID: $CLIENT_PID)"
echo ""
echo "📖 Documentazione:"
echo "   http://localhost:8001/docs (Inference Server Swagger)"
echo "   http://localhost:8002/docs (Client Server Swagger)"
echo ""
echo "🧪 Test rapido:"
echo "   curl http://localhost:8002/inference-server-status"
echo ""
echo "🛑 Per fermare i server:"
echo "   kill $INFERENCE_PID $CLIENT_PID"
echo "   oppure usa: ./stop_servers.sh"
echo ""

# Salva i PID in un file per fermarli facilmente dopo
echo "$INFERENCE_PID" > .inference_server.pid
echo "$CLIENT_PID" > .client_server.pid

# Test rapido di connettività
sleep 1
echo "Verifico la connessione..."
if curl -s http://localhost:8002/inference-server-status | grep -q "online"; then
    echo "✅ Comunicazione Server-to-Server funzionante!"
else
    echo "⚠️  Attenzione: verifica la comunicazione tra i server"
fi

echo ""
echo "I server continueranno ad eseguire in background."
echo "I log sono salvati in inference_server.log e client_server.log"
