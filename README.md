# ROS 2 guide · Brno Mars Rover

Krátký praktický úvod do ROS 2 pro nové členy
[Brno Mars Rover](https://brnomarsrover.cz). Vyzkoušíš si základy ROS2 a na konci si na svém počítači zprovozníš software roveru Freya a projedeš se v simulaci.

Všechno běží v kontejneru s **Ubuntu 24.04, ROS 2 Jazzy a Gazebem Harmonic**,
stejném prostředí, jaké používá rover. Ubuntu instalovat nemusíš.

## Rychlý start (Linux)

```
sudo pacman -S distrobox podman          # Arch;  Fedora: sudo dnf install distrobox podman
git clone https://github.com/BrnoMarsRover/ros2-guide.git ~/ros2-guide
cd ~/ros2-guide
container/create.sh
distrobox enter bmr
container/check.sh --gui
```

Podrobně a s řešením problémů: [kapitola 0](docs/cs/00-prostredi.md).

## Kapitoly

| # | Kapitola | Na konci umíš |
|---|---|---|
| 0 | [Prostředí](docs/cs/00-prostredi.md) | spustit ROS 2 a turtlesim v kontejneru |
| 1 | Co je ROS 2 | ovládat želvu z terminálu, číst graf nodů |
| 2 | Workspace a balíček | postavit vlastní balíček (`colcon build`) |
| 3 | Publisher a subscriber | napsat dva nody, které spolu mluví (Python, ukázka v C++) |
| 4 | Moje želva I | vlastní želva: `cmd_vel` → poloha, parametry |
| 5 | Moje želva II | service, launch file, dvě želvy v namespacech |
| 6 | TF, rviz2, bag | želva v rviz2, watchdog, nahrávání dat |
| 7 | Gazebo *(volitelné)* | řídit robota v simulaci |
| 8 | Náš rover | spustit Freyu, vyznat se v repozitářích, poslat PR |

Kapitoly bez odkazu se teprve píšou.

## Repozitář

```
container/      image (Dockerfile, install.sh), vytvoření a kontrola kontejneru
docs/cs/        kapitoly česky (docs/en/ snad později)
.github/        GitHub Action: sestavení a publikace image
```

Image `ghcr.io/brnomarsrover/ros2-guide:jazzy` sestavuje GitHub Action při
každé změně v `container/` a jednou týdně kvůli aktualizacím. Lokálně:
`container/create.sh --local`.

## Licence

MIT
