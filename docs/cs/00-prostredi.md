# 0 · Prostředí

**Cíl:** mít terminál s Ubuntu 24.04, ROS 2 Jazzy a Gazebem Harmonic, ve kterém
se otevře okno se želvou. Zabere to asi 20 minut, většinou se čeká na stahování.

> Celý tým i rover používají **Ubuntu 24.04 + ROS 2 Jazzy**. Nemusíš ale
> přeinstalovávat počítač. Ubuntu poběží v kontejneru vedle tvého systému.

## Jak to funguje

Používáme [distrobox](https://distrobox.it). Ten spustí Ubuntu jako kontejner
(přes podman nebo docker), ale propojí ho s tvým počítačem:

- **okna** (rviz2, Gazebo) se otevírají normálně na tvé ploše,
- **grafická karta** je v kontejneru k dispozici, takže Gazebo není pomalé,
- **tvoje domovská složka** je v kontejneru vidět na stejné cestě. Kód tedy
  můžeš upravovat ve svém oblíbeném editoru na hostu a v kontejneru ho jen
  spouštět.

Kontejner má navíc vlastní složku pro konfiguraci (`~/.bmr-home`), takže ti
nepřepíše `.bashrc` ani nic dalšího na hostu.

```
tvůj systém (Arch, Fedora, …)
├── ~/ros2-guide, ~/bmr_system …   kód, vidíš ho z hostu i z kontejneru
├── ~/.bmr-home                     domovská složka kontejneru (.bashrc, .ros, …)
└── kontejner „bmr“ = Ubuntu 24.04 + ROS 2 Jazzy + Gazebo Harmonic
```

## Kroky

### 1. Nainstaluj distrobox a podman

| Systém | Příkaz |
|---|---|
| Arch | `sudo pacman -S distrobox podman` |
| Fedora | `sudo dnf install distrobox podman` (podman už většinou máš) |
| Ubuntu, Debian | `sudo apt install distrobox podman` |
| jiný Linux | [distrobox.it](https://distrobox.it/#installation) |
| Windows | viz [Windows](#windows-wsl2) níže |
| macOS | nepodporujeme, Gazebo by v kontejneru běželo bez GPU. Ozvi se, najdeme řešení. |

Místo podmanu stačí i docker, pokud ho už máš (a jsi ve skupině `docker`).

### 2. Stáhni tento repozitář

```
git clone https://github.com/BrnoMarsRover/ros2-guide.git ~/ros2-guide
cd ~/ros2-guide
```

### 3. Vytvoř kontejner

```
container/create.sh
```

Skript zkontroluje, že máš distrobox a podman, a stáhne image (jednou, asi 2–3 GB ke stažení, 7 GB na disku).
Pak vytvoří kontejner `bmr`. Pokud máš grafiku NVIDIA, sám ji připojí.

### 4. Vstup do kontejneru a zkontroluj ho

```
distrobox enter bmr
~/ros2-guide/container/check.sh --gui
```

Na pár sekund by se mělo otevřít okno se želvou a na konci by mělo být
**All set.** Pokud ne, zkopíruj blok `summary` a pošli ho do týmového chatu.

V kontejneru začíná prompt `(bmr)`, třeba `(bmr)jan@notebook:~$`. Podle toho
poznáš, kde zrovna jsi. Kontejner opustíš příkazem `exit`, znovu do něj vstoupíš přes
`distrobox enter bmr`.

### 5. Želva

```
ros2 run turtlesim turtlesim_node
```

Otevři **druhý terminál**, v něm znovu `distrobox enter bmr`, a spusť:

```
ros2 run turtlesim turtle_teleop_key
```

Šipkami teď řídíš želvu. Když tohle funguje, máš hotovo. 🐢

### 6. GitHub (stačí do kapitoly 8)

Týmové repozitáře jsou soukromé. Budeš potřebovat:

1. účet na GitHubu a pozvánku do organizace
   [BrnoMarsRover](https://github.com/BrnoMarsRover). Napiš o ni do chatu,
2. SSH klíč. Pokud ho ještě nemáš, vytvoř ho **na hostu**:
   `ssh-keygen -t ed25519`, a obsah `~/.ssh/id_ed25519.pub` vlož na
   [github.com/settings/keys](https://github.com/settings/keys).

Kontejner používá tvoje `~/.ssh` a git konfiguraci z hostu a týmové
repozitáře stahuje přes SSH. Zda vše funguje, ukáže `check.sh` v řádcích
`GitHub`.

## Co se právě stalo

- `create.sh` stáhl image `ghcr.io/brnomarsrover/ros2-guide:jazzy` a vytvořil
  z něj kontejner. Co v image je, popisuje [`container/install.sh`](../../container/install.sh).
- Každý terminál v kontejneru má automaticky načtený ROS (`/etc/bmr-ros.sh`).
  Proč je to potřeba, uvidíme v kapitole 2.
- Dva programy (`turtlesim_node` a `turtle_teleop_key`) jsou dva **nody**.
  Jeden posílá příkazy, druhý je poslouchá. O tom je kapitola 1.

## Bezpečnost: ROS jen na tvém počítači

ROS 2 standardně komunikuje s ostatními počítači v síti. Kdyby ses
v dílně připojil k Wi-Fi roveru, tvoje `cmd_vel` by mohly opravdu
pohnout Freyou. Proto má kontejner nastaveno:

```
ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
```

ROS tak vidí jen nody na tvém počítači. Jak se připojit k roveru, ukáže
kapitola 8.

## Když to nefunguje

| Problém | Řešení |
|---|---|
| `distrobox: command not found` | krok 1 |
| `create.sh` hlásí, že docker neodpovídá | `sudo systemctl start docker` a být ve skupině `docker` (`sudo usermod -aG docker $USER`, pak se odhlásit), nebo radši nainstalovat podman |
| okno se neotevře, `could not connect to display` | na hostu spusť `xhost +si:localuser:$USER` a zkus to znovu |
| `check.sh` píše `OpenGL without GPU (llvmpipe)` | na NVIDII: `container/create.sh --replace` (musí být nainstalovaný ovladač na hostu). Jinak napiš do chatu i se summary. |
| Gazebo nebo rviz2 padá na Waylandu | už je nastaveno `QT_QPA_PLATFORM=xcb`; ověř `echo $QT_QPA_PLATFORM` |
| chci začít znovu načisto | `distrobox rm bmr`, `rm -rf ~/.bmr-home`, a znovu krok 3 |
| vyšla nová verze image | `container/create.sh --replace` (tvůj kód ani `~/.bmr-home` se nesmažou) |

## Bez kontejneru

### Ubuntu 24.04

Kontejner nepotřebuješ, stačí nainstalovat totéž, co je v image:

```
sudo ~/ros2-guide/container/install.sh
```

### Windows (WSL2)

*Zatím neotestováno.* V PowerShellu: `wsl --install -d Ubuntu-24.04`. Pak
v Ubuntu terminálu naklonuj repozitář a spusť `sudo ~/ros2-guide/container/install.sh`.
Okna fungují přes WSLg na Windows 11 a aktuálních Windows 10.

## Editor

Kód leží ve tvé domovské složce, takže můžeš použít jakýkoli editor na hostu.
Spouštíš ho ale v kontejneru. Pokud chceš ve VS Code napovídání pro ROS
(`rclpy`), nainstaluj si rozšíření **Dev Containers** a použij
*Attach to Running Container…* → `bmr`.

---

Další: [1 · Co je ROS 2](01-co-je-ros.md)
