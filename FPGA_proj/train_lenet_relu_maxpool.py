import argparse
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader
from torchvision import datasets, transforms


class LeNetReLUMaxPool(nn.Module):
    """LeNet-style model matched to the HLS direction: ReLU + MaxPool."""

    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 6, kernel_size=5)
        self.conv2 = nn.Conv2d(6, 16, kernel_size=5)
        self.conv3 = nn.Conv2d(16, 120, kernel_size=5)
        self.fc1 = nn.Linear(120, 84)
        self.fc2 = nn.Linear(84, 10)

    def forward(self, x):
        # Input: [N, 1, 32, 32]
        x = F.relu(self.conv1(x))      # [N, 6, 28, 28]
        x = F.max_pool2d(x, 2)         # [N, 6, 14, 14]
        x = F.relu(self.conv2(x))      # [N, 16, 10, 10]
        x = F.max_pool2d(x, 2)         # [N, 16, 5, 5]
        x = F.relu(self.conv3(x))      # [N, 120, 1, 1]
        x = torch.flatten(x, 1)        # [N, 120]
        x = F.relu(self.fc1(x))        # [N, 84]
        return self.fc2(x)             # [N, 10], final logits


def evaluate(model, loader, device):
    model.eval()
    correct = 0
    total = 0
    loss_sum = 0.0
    criterion = nn.CrossEntropyLoss(reduction="sum")

    with torch.no_grad():
        for images, labels in loader:
            images = images.to(device)
            labels = labels.to(device)
            logits = model(images)
            loss_sum += criterion(logits, labels).item()
            pred = logits.argmax(dim=1)
            correct += (pred == labels).sum().item()
            total += labels.numel()

    return loss_sum / total, correct / total


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--batch-size", type=int, default=128)
    parser.add_argument("--test-batch-size", type=int, default=256)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--data-dir", type=Path, default=Path("data"))
    parser.add_argument("--out", type=Path, default=Path("lenet_relu_maxpool_float.pth"))
    args = parser.parse_args()

    torch.manual_seed(0)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # Match the current project input convention:
    # MNIST 28x28 -> pad to 32x32, then normalize 0..1 to -1..1.
    transform = transforms.Compose(
        [
            transforms.Pad(2),
            transforms.ToTensor(),
            transforms.Normalize((0.5,), (0.5,)),
        ]
    )

    train_set = datasets.MNIST(args.data_dir, train=True, download=True, transform=transform)
    test_set = datasets.MNIST(args.data_dir, train=False, download=True, transform=transform)
    train_loader = DataLoader(train_set, batch_size=args.batch_size, shuffle=True, num_workers=2)
    test_loader = DataLoader(test_set, batch_size=args.test_batch_size, shuffle=False, num_workers=2)

    model = LeNetReLUMaxPool().to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    criterion = nn.CrossEntropyLoss()

    print(f"device={device}")
    for epoch in range(1, args.epochs + 1):
        model.train()
        train_loss = 0.0
        seen = 0

        for images, labels in train_loader:
            images = images.to(device)
            labels = labels.to(device)

            optimizer.zero_grad()
            logits = model(images)
            loss = criterion(logits, labels)
            loss.backward()
            optimizer.step()

            batch = labels.numel()
            train_loss += loss.item() * batch
            seen += batch

        test_loss, test_acc = evaluate(model, test_loader, device)
        print(
            f"epoch={epoch} "
            f"train_loss={train_loss / seen:.6f} "
            f"test_loss={test_loss:.6f} "
            f"test_acc={test_acc * 100:.2f}%"
        )

    torch.save(
        {
            "model": model.state_dict(),
            "arch": "LeNetReLUMaxPool",
            "input": "MNIST Pad(2), Normalize((0.5,), (0.5,))",
            "epochs": args.epochs,
            "test_acc": test_acc,
        },
        args.out,
    )
    print(f"saved={args.out}")


if __name__ == "__main__":
    main()
