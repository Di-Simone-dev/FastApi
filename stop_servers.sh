#!/bin/bash

# Script per fermare entrambi i server

echo "=========================================="
echo "Arresto Server-to-Server Architecture"
echo "=========================================="
echo ""

# Funzione per fermare un processo
stop_server() {
    local pid_file=$1
    local server_name=$2
    
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if kill -0 $pid 2>/dev/null; then
            echo "🛑 Arresto $server_name (PID: $pid)..."
            kill $pid
            sleep 1
            if kill -0 $pid 2>/dev/null; then
                echo "   Forzo l'arresto..."
                kill -9 $pid 2>/dev/null
            fi
            echo "   ✓ $server_name arrestato"
        else
            echo "   ℹ️  $server_name non è in esecuzione"
        fi
        rm "$pid_file"
    else
        echo "   ℹ️  File PID non trovato per $server_name"
    fi
}

# Arresta i server
stop_server ".inference_server.pid" "Inference Server"
stop_server ".client_server.pid" "Client Server"

# Alternativa: cerca e killa tutti i processi uvicorn sulla porta specifica
echo ""
echo "Verifica processi rimanenti..."

# Verifica porta 8001
if lsof -Pi :8001 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Processo ancora attivo sulla porta 8001"
    pid=$(lsof -Pi :8001 -sTCP:LISTEN -t)
    echo "   Vuoi terminarlo? (PID: $pid)"
    read -p "   [y/N]: " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        kill -9 $pid
        echo "   ✓ Processo terminato"
    fi
else
    echo "✓ Porta 8001 libera"
fi

# Verifica porta 8002
if lsof -Pi :8002 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Processo ancora attivo sulla porta 8002"
    pid=$(lsof -Pi :8002 -sTCP:LISTEN -t)
    echo "   Vuoi terminarlo? (PID: $pid)"
    read -p "   [y/N]: " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        kill -9 $pid
        echo "   ✓ Processo terminato"
    fi
else
    echo "✓ Porta 8002 libera"
fi

echo ""
echo "=========================================="
echo "✅ Operazione completata"
echo "=========================================="
