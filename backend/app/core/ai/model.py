import torch
import torch.nn as nn

CLASS_NAMES = {
    0: "BenchPress",
    1: "BodyWeightSquats",
    2: "CleanAndJerk",
    3: "HandstandPushups",
    4: "JumpingJack",
    5: "Lunges",
    6: "PullUps",
    7: "PushUps",
    8: "WallPushups"
}


class STGCN_Nexus(nn.Module):
    def __init__(self, num_classes=9):
        super(STGCN_Nexus, self).__init__()
        self.bn = nn.BatchNorm1d(2 * 17)
        self.conv1 = nn.Sequential(
            nn.Conv2d(2, 64, kernel_size=(9, 1), padding=(4, 0)),
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.MaxPool2d((2, 1))
        )
        self.conv2 = nn.Sequential(
            nn.Conv2d(64, 128, kernel_size=(1, 3), padding=(0, 1)),
            nn.BatchNorm2d(128),
            nn.ReLU(),
            nn.AdaptiveAvgPool2d(1)
        )
        self.fc = nn.Linear(128, num_classes)

    def forward(self, x):
        N, C, T, V = x.size()
        x = x.permute(0, 1, 3, 2).contiguous().view(N, C * V, T)
        x = self.bn(x)
        x = x.view(N, C, V, T).permute(0, 1, 3, 2).contiguous()
        x = self.conv1(x)
        x = self.conv2(x)
        x = x.view(N, -1)
        return self.fc(x)
