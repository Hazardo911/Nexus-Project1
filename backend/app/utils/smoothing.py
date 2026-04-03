_smooth_state = {}


def smooth_values(features: dict, alpha: float = 0.3) -> dict:
    result = {}
    for k, v in features.items():
        if not isinstance(v, (int, float)):
            result[k] = v
            continue
        prev = _smooth_state.get(k, v)
        new = prev * (1 - alpha) + v * alpha
        _smooth_state[k] = new
        result[k] = new
    return result


def reset_smoothing() -> None:
    _smooth_state.clear()
