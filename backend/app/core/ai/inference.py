import logging

import torch

from app.core.ai.model import STGCN_Nexus, CLASS_NAMES

_model = None
_device = None


def get_model():
    global _model, _device
    if _model is None:
        _device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        _model = STGCN_Nexus(num_classes=9).to(_device)
        try:
            _model.load_state_dict(
                torch.load("nexus_stgcn_v2.pth", map_location=_device)
            )
            logging.info("Model weights loaded successfully")
        except Exception as e:
            logging.error(f"Failed to load model weights: {e}")
            raise
        _model.eval()
    return _model, _device


def model_predict(tensor: torch.Tensor) -> dict:
    if tensor is None:
        raise ValueError("tensor must not be None")
    if tensor.ndim != 4 or tensor.size(1) != 2:
        raise ValueError("tensor shape must be (1,2,T,17)")
    model, device = get_model()
    with torch.no_grad():
        logits = model(tensor.to(device))
        probabilities = torch.softmax(logits, dim=1)[0]
        class_id = torch.argmax(probabilities).item()
        confidence = probabilities[class_id].item()
        top_indices = torch.topk(probabilities, k=min(3, probabilities.numel())).indices.tolist()
    return {
        "class_id": class_id,
        "exercise": CLASS_NAMES[class_id],
        "confidence": round(confidence, 3),
        "top_k": [
            {
                "class_id": idx,
                "exercise": CLASS_NAMES[idx],
                "confidence": round(probabilities[idx].item(), 3),
            }
            for idx in top_indices
        ],
    }
