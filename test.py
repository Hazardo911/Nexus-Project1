import torch
import numpy as np
import json

# --- MODEL ---
import torch.nn as nn

class NexusBrain(nn.Module):
    def __init__(self, num_classes=9):
        super().__init__()
        self.s_conv = nn.Conv2d(2, 128, kernel_size=(1, 1))
        self.bn1 = nn.BatchNorm2d(128)

        self.s_conv2 = nn.Conv2d(128, 128, kernel_size=(1, 1))
        self.bn2 = nn.BatchNorm2d(128)

        self.t_conv = nn.Conv2d(128, 256, kernel_size=(9, 1), padding=(4, 0))
        self.bn3 = nn.BatchNorm2d(256)

        self.pool = nn.AdaptiveAvgPool2d((1, 1))
        self.fc = nn.Linear(256, num_classes)

    def forward(self, x):
        x = torch.relu(self.bn1(self.s_conv(x)))
        x = torch.relu(self.bn2(self.s_conv2(x)))
        x = torch.relu(self.bn3(self.t_conv(x)))
        x = self.pool(x)
        x = x.view(x.size(0), -1)
        return self.fc(x)

# --- LOAD LABELS ---
with open("label_map.json") as f:
    LABELS = json.load(f)

# --- LOAD MODEL ---
model = NexusBrain(num_classes=9)
model.load_state_dict(torch.load("nexus_model.pth", map_location="cpu"))
model.eval()

# --- LOAD TEST FILE ---
data = np.load("c:\\Users\\Mayur Anand\\Downloads\\Test_Data\\JumpingJack_v_JumpingJack_g15_c01.avi_coords.npy")   # ← CHANGE THIS

# SAME LOGIC AS HIS CODE
if data.shape[-1] == 2:
    data = data.transpose(2, 0, 1)

if data.shape[1] < 300:
    padding = np.zeros((2, 300 - data.shape[1], 17))
    data = np.concatenate((data, padding), axis=1)
else:
    data = data[:, :300, :]

tensor = torch.from_numpy(data).float().unsqueeze(0)

# --- PREDICT ---
with torch.no_grad():
    output = model(tensor)
    probs = torch.softmax(output, dim=1)
    pred = torch.argmax(probs, dim=1).item()

print("Prediction index:", pred)
print("Prediction label:", LABELS[str(pred)])
print("Probabilities:", probs)