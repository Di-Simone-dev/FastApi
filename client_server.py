from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import httpx
import os

app = FastAPI(title="Client API Server")

# URL del server di inferenza ONNX
INFERENCE_SERVER_URL = "http://localhost:8001"

@app.post("/classify")
async def classify_image(file: UploadFile = File(...)):
    """
    Riceve un'immagine e la invia al server di inferenza ONNX
    """
    try:
        # Leggi il contenuto del file
        contents = await file.read()
        
        # Prepara il file per l'invio
        files = {
            'file': (file.filename, contents, file.content_type)
        }
        
        # Invia la richiesta al server di inferenza
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{INFERENCE_SERVER_URL}/predict",
                files=files
            )
        
        # Verifica che la risposta sia OK
        if response.status_code == 200:
            result = response.json()
            return {
                "status": "success",
                "prediction": result['class_name'],
                "confidence": result['confidence'],
                "source": "ONNX Inference Server"
            }
        else:
            return JSONResponse(
                status_code=response.status_code,
                content={
                    "status": "error",
                    "message": "Inference server error",
                    "details": response.text
                }
            )
            
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=503,
            detail=f"Cannot connect to inference server: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}"
        )

@app.post("/classify-from-path")
async def classify_from_path(image_path: str):
    """
    Riceve un percorso di un'immagine sul server e la invia per classificazione
    Utile per processare immagini già presenti sul server
    """
    try:
        # Verifica che il file esista
        if not os.path.exists(image_path):
            raise HTTPException(status_code=404, detail="Image file not found")
        
        # Leggi il file
        with open(image_path, 'rb') as f:
            contents = f.read()
        
        # Prepara il file per l'invio
        files = {
            'file': (os.path.basename(image_path), contents, 'image/png')
        }
        
        # Invia la richiesta al server di inferenza
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{INFERENCE_SERVER_URL}/predict",
                files=files
            )
        
        if response.status_code == 200:
            result = response.json()
            return {
                "status": "success",
                "image_path": image_path,
                "prediction": result['class_name'],
                "confidence": result['confidence']
            }
        else:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Inference error: {response.text}"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {
        "message": "Client API Server",
        "endpoints": {
            "POST /classify": "Upload an image for classification",
            "POST /classify-from-path": "Classify image from server path",
            "GET /health": "Health check",
            "GET /inference-server-status": "Check inference server status"
        }
    }

@app.get("/health")
async def health_check():
    """Health check del server client"""
    return {"status": "ok", "server": "client"}

@app.get("/inference-server-status")
async def check_inference_server():
    """
    Verifica lo stato del server di inferenza
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{INFERENCE_SERVER_URL}/health")
        
        if response.status_code == 200:
            return {
                "inference_server": "online",
                "url": INFERENCE_SERVER_URL,
                "response": response.json()
            }
        else:
            return {
                "inference_server": "error",
                "status_code": response.status_code
            }
            
    except Exception as e:
        return {
            "inference_server": "offline",
            "error": str(e)
        }

# Endpoint bonus: classificazione batch di più immagini
@app.post("/classify-batch")
async def classify_batch(files: list[UploadFile] = File(...)):
    """
    Classifica multiple immagini in una sola richiesta
    """
    results = []
    
    for file in files:
        try:
            contents = await file.read()
            
            files_data = {
                'file': (file.filename, contents, file.content_type)
            }
            
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{INFERENCE_SERVER_URL}/predict",
                    files=files_data
                )
            
            if response.status_code == 200:
                result = response.json()
                results.append({
                    "filename": file.filename,
                    "status": "success",
                    "prediction": result['class_name'],
                    "confidence": result['confidence']
                })
            else:
                results.append({
                    "filename": file.filename,
                    "status": "error",
                    "error": response.text
                })
                
        except Exception as e:
            results.append({
                "filename": file.filename,
                "status": "error",
                "error": str(e)
            })
    
    return {
        "total": len(files),
        "results": results
    }
