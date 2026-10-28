# ROS 2 guide pro BMR – koncept

Pracovní dokument: co chceme postavit a proč. Až se dohodneme, z osnovy se
stanou kapitoly v `docs/cs/`.

## Cíl

Nový člen za dva až tři večery dojde od „nemám Ubuntu“ k tomu, že:

1. spustí `bmr-system/setup.sh`, projede si Freyu v Gazebu,
2. chápe, co vidí v `ros2 topic list` a v `rqt_graph`,
3. ví, kam v repozitářích patří jeho kód, a umí udělat PR.

Nejde o kompletní kurz ROS 2. Jde o nejkratší cestu k týmovému repu.
Inspirací je styl *Introduction to ROS 2* (Rico): postupné stavění konceptů.
Text a příklady jsou ale vlastní, kratší a v Pythonu.

## Hlavní rozhodnutí

### 1. Prostředí: „terminál s Ubuntu 24.04“, stejné jako u roveru

`bmr-system` podporuje Ubuntu 24.04 + Jazzy + Gazebo Harmonic a jeho
`test/docker_test.sh` ukazuje, že `setup.sh` funguje i v čistém kontejneru.
Proto tutoriál **nedělá vlastní instalaci ROS**: dá člověku Ubuntu 24.04
v kontejneru, a kapitola o roveru v tomtéž prostředí jen spustí `./setup.sh`.

| Systém | Cesta | Poznámka |
|---|---|---|
| Linux (Arch, Fedora, ostatní) | **distrobox** + podman/docker | GUI (Wayland/X11) i GPU fungují bez nastavování, pro Gazebo zásadní |
| Windows | WSL2 s Ubuntu 24.04 | WSLg řeší GUI, uvnitř je to „normální Ubuntu“ |
| Ubuntu 24.04 | nativně | nic dalšího není třeba |
| macOS | nepodporováno | Docker na Macu nemá GPU, Gazebo by běželo přes VNC a softwarové vykreslování; případně „best effort“ odkaz |

Proč distrobox a ne devcontainer + noVNC: sdílí s hostem displej, `/dev/dri`
a zvuk, takže rviz2 i Gazebo běží s akcelerací. Nenutí VS Code a nemusíme
udržovat VNC vrstvu. Na Fedoře i Archu je v repozitářích.

Pozor: distrobox standardně sdílí `$HOME` s hostem. `setup.sh` přepisuje
`~/.bashrc`, `~/.tmux.conf` a volitelně `~/.zshrc` a `chsh`. Kontejner proto
vytváříme s **oddělenou domovskou složkou**:

```
distrobox create --name bmr --image <image> --home ~/.bmr-home   # + --nvidia na NVIDIA
# (dělá to container/create.sh)
distrobox enter bmr
```

**Image**: vlastní `ghcr.io/brnomarsrover/ros2-guide:jazzy` = `ubuntu:24.04`
\+ `ros-jazzy-desktop` + Gazebo Harmonic (`ros-jazzy-ros-gz`) + nástroje
z `APT_TOOLS` v `setup.sh`. Sestavuje ho GitHub Action. Nováček tak stahuje
jeden image místo půlhodinové instalace. `setup.sh` pak v kapitole 8 hotové
kroky jen rychle přeskočí.
*(Alternativa bez vlastního image: čisté `ubuntu:24.04` a v kontejneru spustit
`setup.sh`. Je to jednodušší na údržbu, ale první krok je hned 30 minut instalace
a k tomu se naklonuje celý rover.)*

### 2. Python, s jednou ukázkou C++

Všechny příklady jsou v Pythonu (`rclpy`). V kapitole 3 je jednou publisher +
subscriber v Pythonu i C++ vedle sebe, včetně `setup.py` vs. `CMakeLists.txt`,
ať vidí, že koncepty jsou stejné.

### 3. Jazyk

Primárně česky, angličtina později v `docs/en/`. Termíny (node, topic,
launch file, namespace…) necháváme anglicky, protože tak je uvidí v chybových
hláškách, dokumentaci i v našich READMEs, které jsou anglicky.

### 4. Vlastní želva jako nit celého tutoriálu

Od kapitoly 4 si každý staví `my_turtle`: node, který z `cmd_vel` (Twist)
integruje polohu a publikuje ji. Postupně se nabaluje to, co dělá
`kinematics` na Freye:

| Krok | Želva | Na roveru odpovídá |
|---|---|---|
| sub `cmd_vel` → pub pozice, timer | základ | `kinematics`: cmd → odometrie |
| parametry (max. rychlost, frekvence) | YAML config | `config/freya/default.yaml` |
| service `reset` | | služby |
| launch: dvě želvy v namespacech `turtle_1`, `turtle_2` | | `freya_1`, víc roverů v simulaci |
| TF `turtle_1_odom` → `turtle_1_base_link`, zobrazení v rviz2 | | konvence frames |
| watchdog: bez příkazů do 0,5 s zastaví | | bezpečnost v `kinematics` |
| (Gazebo) stejný teleop ovládá diff-drive robota | | `simulation` |

Ovládání je přes `teleop_twist_keyboard` a na začátku ještě přes turtlesim. Když
pak nováček otevře `kinematics` nebo `example_package`, uvidí známé věci.

Kreslení vlastní želvy: hlavní cesta je **rviz2** (Marker/TF), protože to
pak používají pořád. Jako zábavný bonus jde přidat okno v `tkinter`.

### 5. Formát kapitoly

Každá kapitola má 30–60 minut a stejnou kostru:

> **Cíl** → **Kroky** (příkazy ke zkopírování) → **Co se právě stalo** →
> **Když to nefunguje** → **Úkol** (řešení v `solutions/`)

Úkol je volitelný. Teoretické kapitoly (1) ho nemají, příkazy se zkoušejí průběžně při čtení.

Text v Markdownu nezalamujeme na pevnou šířku: odstavec nebo odrážka je na jednom řádku, nový řádek nanejvýš na konci věty. Zalamování zvládne každý editor i prohlížeč sám.

## Osnova

| # | Kapitola | Na konci umí |
|---|---|---|
| 0 | **Prostředí**: distrobox / WSL2, první spuštění, VS Code | `ros2 run turtlesim turtlesim_node` otevře okno |
| 1 | **Co je ROS 2** + turtlesim z CLI: node, topic, message, service, `rqt_graph` | ovládat želvu z terminálu, číst graf |
| 2 | **Workspace a balíček**: workspace, balíček `my_turtle`, závislosti, `colcon build`, `source`, underlay/overlay | spustit vlastní balíček přes `ros2 run` |
| 3 | **Publisher a subscriber** (Python, jednou i C++) | dva vlastní nody spolu mluví |
| 4 | **Moje želva I**: `cmd_vel` → pozice, timer, parametry, YAML | želva se hýbe z teleopu |
| 5 | **Moje želva II**: service, launch file, namespaces, remapping | dvě želvy z jednoho launch |
| 6 | **Nástroje**: TF, rviz2, `ros2 bag`, watchdog | želva v rviz2, nahraný a přehraný bag |
| 7 | **Gazebo** *(volitelné, pro simulační tým)*: svět, robot, `ros_gz_bridge`, `use_sim_time` | ovládat robota v Gazebu stejným teleopem |
| 8 | **Náš rover**: `setup.sh`, `env.sh` (vrstvy workspace, `cb`, `bmr_build`), komponenty bmr/erc/urc, spuštění simulace (tmux, tmuxinator), cesta `cmd_vel` → `kinematics`, konvence, workflow (větve `<jmeno>/<tema>`, PR, CI) | jezdit s Freyou, najít a přečíst README libovolného repa |
| + | **Tahák**: příkazy ROS 2, týmové aliasy (`rtl`, `cb`, `bmr_build`…), tmux | |

Jádro jsou kapitoly 0–6, 7 je pro simulační tým a 8 je napojení na rover.

## Struktura repa

```
ros2-guide/
├── README.md                  rozcestník, rychlý start
├── container/
│   ├── install.sh             ROS Jazzy desktop + Gazebo Harmonic + nástroje (image i nativní Ubuntu/WSL)
│   ├── Dockerfile             ubuntu:24.04 + install.sh + balíčky pro distrobox
│   ├── create.sh              distrobox create s oddělenou home, detekce NVIDIA
│   └── check.sh               kontrola prostředí, souhrn pro hlášení problémů
├── docs/cs/00-prostredi.md … 08-rover.md, tahak.md
├── ws/src/                    kostry balíčků pro cvičení (my_turtle, …)
├── solutions/                 řešení úkolů po kapitolách
└── .github/workflows/         build image + kontrola, že se cvičení i řešení zbuildí
```
