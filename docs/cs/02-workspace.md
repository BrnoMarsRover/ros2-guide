# 2 · Workspace a balíček

**Cíl:** založit balíček `my_turtle`, postavit ho a spustit přes `ros2 run`.

Chceš napsat vlastní program pro ROS 2. V tomhle tutoriálu to bude želva, kterou budeš rozvíjet až do kapitoly 6. Tato kapitola tě provede tím, jak zařadit vlastní kód do svého prostředí ROS 2.

## Workspace

Programy pro ROS 2 leží ve **workspace**. Workspace je složka, ve které vyvíjíš své balíčky a buildíš je společně. Obvykle máš jeden workspace na projekt. Pro tento tutoriál ho založ v repozitáři:

```
mkdir -p ~/ros2-guide/ws/src
cd ~/ros2-guide/ws
```

Do `src/` patří zdrojový kód tvých balíčků. Je to jediná složka workspace, kterou píšeš ty.

## Balíček

Programy pro ROS 2 se seskupují do **balíčků** (*packages*). Balíček má vlastní jméno, seznam závislostí, zprávy, konfigurace a programy, které jde spustit. Už jsi ho používal: `ros2 run turtlesim turtlesim_node` spustí program `turtlesim_node` z balíčku `turtlesim`.

Balíček může být v jakémkoli jazyce, pro který existuje klientská knihovna nad rcl (viz vrstvy, kapitola 1). Nejčastější jsou Python (`ament_python`) a C++ (`ament_cmake`). Jazyky se liší tím, jak se balíček staví, nody v nich ale spolu komunikují úplně stejně. My budeme psát v Pythonu s využitím `rclpy`.

Vytvoř balíček v `src/`:

```
cd ~/ros2-guide/ws/src
ros2 pkg create --build-type ament_python --dependencies rclpy --node-name turtle my_turtle
```

- `--build-type ament_python` znamená balíček v Pythonu.
- `--dependencies rclpy` je seznam závislostí.
- `--node-name turtle` rovnou vytvoří program `turtle`.
- `my_turtle` je jméno balíčku. Používej jen malá písmena, číslice a podtržítka.

Varování `Unknown license 'TODO: License declaration'` můžeš ignorovat.

Vznikla tahle struktura:

```
my_turtle/
├── package.xml           popis balíčku: jméno, autor, závislosti
├── setup.py              instalace balíčku a seznam programů pro ros2 run
├── setup.cfg             kam se programy nainstalují (neměníš)
├── resource/my_turtle    prázdná značka, podle které ROS balíček najde (neměníš)
├── my_turtle/
│   ├── __init__.py
│   └── turtle.py         kód programu turtle, zatím jen print
└── test/                 automatické kontroly stylu (neměníš)
```

Kód je v `my_turtle/turtle.py`. Zatím je to obyčejný Python, plnohodnotný node z něj bude v kapitole 3:

```python
def main():
    print('Hi from my_turtle.')
```

Aby šel spustit přes `ros2 run`, musí být zapsaný v `setup.py`:

```python
    entry_points={
        'console_scripts': [
            'turtle = my_turtle.turtle:main'
        ],
    },
```

Řádek znamená: program `turtle` spustí funkci `main` ze souboru `my_turtle/turtle.py`. Každý další program, který do balíčku přidáš, potřebuje vlastní řádek.

## Závislosti

V `package.xml` je popis balíčku pro ROS. Nejdůležitější jsou v něm závislosti:

```xml
  <depend>rclpy</depend>
```

`<depend>` říká, že balíček potřebuje jiný balíček, aby se postavil i spustil. Seznam používají dva nástroje:

- **colcon** podle něj určí pořadí buildu. Když máš ve workspace víc balíčků a jeden používá druhý, postaví se nejdřív ten druhý.
- **rosdep** podle něj doinstaluje, co chybí:

```
rosdep update
rosdep install --from-paths src --ignore-src -y
```

`rosdep update` stáhne seznam balíčků a stačí ho pustit jednou za čas. `rosdep install` projde `package.xml` všech balíčků v `src/` a přes apt nainstaluje, co chybí. `--ignore-src` přeskočí balíčky, které máš ve workspace. V kontejneru je pro tento tutoriál všechno nainstalované, takže nic nedoinstaluje. Využiješ to ale u cizího kódu nebo na novém počítači.

Závislosti přidáváš do `package.xml` ručně, jakmile začneš používat další balíček. Když závislost zapomeneš zapsat, u tebe to fungovat může, protože balíček náhodou máš nainstalovaný, ale jinde nemusí.

## Build

Python se nekompiluje, proč tedy build? Balíček se musí **nainstalovat** na místo, kde ho ROS najde, včetně programů z `entry_points`. U C++ se navíc kompiluje. Obojí udělá nástroj **colcon** (collective construction):

```
cd ~/ros2-guide/ws
colcon build --symlink-install
```

```
Starting >>> my_turtle
Finished <<< my_turtle [1.38s]

Summary: 1 package finished [1.49s]
```

colcon se pouští vždycky z **kořene workspace**, ne z `src/` ani ze složky balíčku, jinak si uděláš bordel. Najde všechny balíčky v `src/`, seřadí je podle závislostí a každý postaví a nainstaluje. Ve workspace teď přibyly tři složky:

```
ws/
├── src/        tvůj kód
├── build/      mezivýsledky buildu
├── install/    hotové, nainstalované balíčky
└── log/        logy z buildu, když něco selže
```

`build/`, `install/` a `log/` jdou kdykoli smazat a vzniknou znovu. Do gitu nepatří, v tomhle repozitáři je ignoruje `ws/.gitignore`.

Bez použití `--symlink-install` colcon zkopíruje soubory ze `src/` do `install/`. Při použití `--symlink-install` místo kopie vytvoří *symbolické odkazy* na soubory v `src/`. Když pak upravíš kód, změna se projeví hned, bez nového buildu. Znovu buildit musíš, pokud:

- přidáš nový program nebo změníš `setup.py` či `package.xml`,
- přidáš nový balíček,
- změníš kód v C++ (ten se musí znovu zkompilovat).

## Spuštění: `source`

Pokud se balíček pokusíš spustit:

```
ros2 run my_turtle turtle
```

```
Package 'my_turtle' not found
```

Balíček máš nainstalovaný, ale terminál o tom neví. Svůj workspace musíš načíst:

```
source install/setup.bash
ros2 run my_turtle turtle
```

```
Hi from my_turtle.
```

`source install/setup.bash` přidá cesty z `install/` do proměnných prostředí, podle kterých `ros2` hledá balíčky. Platí to jen pro **tento terminál**. V každém novém terminálu je potřeba:

```
source ~/ros2-guide/ws/install/setup.bash
```

Pokud to nechceš psát pořád, můžeš využít toho, že každý terminál při startu načítá soubor `~/.bashrc`. Pro náš kontejner se používá `~/.bmr-home/.bashrc`, aby sis tady nezměnil systémové nastavení. Když sem dopíšeš tento řádek, bude tvůj balíček dostupný v každém terminálu kontejneru a nemusíš ho pokaždé načítat sám:

```
[ -f ~/ros2-guide/ws/install/setup.bash ] && source ~/ros2-guide/ws/install/setup.bash
```

`[ -f … ] &&` znamená „jen pokud soubor existuje“. Bez toho by každý nový terminál vypsal chybu, dokud workspace nepostavíš nebo když smažeš `install/`.

Po přidání nového balíčku je potřeba sourcovat znovu, jinak ho terminál nenajde.

## Underlay a overlay

Teď máš načtená dvě prostředí nad sebou:

```
~/ros2-guide/ws/install   overlay:  my_turtle
/opt/ros/jazzy            underlay: rclpy, turtlesim, rviz2, …
```

**Underlay** je prostředí, na kterém stavíš. **Overlay** je tvůj workspace nad ním. Tvůj balíček používá `rclpy` z underlaye a nemusíš ho mít ve workspace. Když je ale stejný balíček v obou vrstvách, overlay nahradí underlay. Díky tomu můžeš opravit nebo upravit cizí balíček, aniž bys sahal do systému.

Vyzkoušej si to na turtlesimu. Teď se načítá z:

```
ros2 pkg prefix turtlesim
```

```
/opt/ros/jazzy
```

Stáhni si jeho zdrojový kód do workspace:

```
cd ~/ros2-guide/ws
git clone -b jazzy https://github.com/ros/ros_tutorials.git src/ros_tutorials
```

V `src/ros_tutorials/turtlesim/src/turtle_frame.cpp` změň titulek okna z `setWindowTitle("TurtleSim");` na `setWindowTitle("BMR TurtleSim");`. Pak postav jen tenhle balíček. Je v C++, takže to může trvat:

```
colcon build --symlink-install --packages-select turtlesim
```

colcon tě varuje, že turtlesim už je v underlayi (`Some selected packages are already built in one or more underlay workspaces`). Přesně to teď chceš, varování můžeš ignorovat. Otevři nový terminál (`distrobox enter bmr`) a v něm:

```
source ~/ros2-guide/ws/install/setup.bash
ros2 pkg prefix turtlesim
ros2 run turtlesim turtlesim_node
```

`ros2 pkg prefix` teď ukáže `~/ros2-guide/ws/install/turtlesim` a okno se jmenuje *BMR TurtleSim*. Původní turtlesim je pořád nainstalovaný, tvoje verze ho jen překryla.

Nový terminál je potřeba proto, že `source` cesty přidává, ale nikdy je neodebírá. V terminálu, kde už něco načteného máš, se vrstvy můžou nečekaně míchat.

Upravený turtlesim už nebudeš potřebovat, smaž ho:

```
rm -rf src/ros_tutorials build/turtlesim install/turtlesim
```

## Shrnutí

Máš workspace s balíčkem `my_turtle`, který jde spustit přes `ros2 run`. Postup je pokaždé stejný:

1. kód v `src/<balíček>/`, programy zapsané v `setup.py`, závislosti v `package.xml`,
2. `colcon build --symlink-install` z kořene workspace,
3. `source install/setup.bash` a `ros2 run <balíček> <program>`.

Tvůj workspace je overlay nad ROS v `/opt/ros/jazzy`. Workspace můžou ležet ve víc vrstvách nad sebou a horní vrstva vyhrává.

V kapitole 3 z `turtle.py` uděláš opravdový node a napíšeš první publisher a subscriber.

| příkaz | co dělá |
|---|---|
| `ros2 pkg create --build-type ament_python --dependencies <závislosti> --node-name <program> <balíček>` | nový balíček v Pythonu |
| `rosdep install --from-paths src --ignore-src -y` | doinstaluje závislosti z `package.xml` |
| `colcon build --symlink-install` | postaví všechny balíčky ve workspace |
| `colcon build --packages-select <balíček>` | postaví jen vybrané balíčky |
| `colcon list` | balíčky, které colcon ve workspace vidí |
| `source install/setup.bash` | načte workspace do terminálu |
| `ros2 pkg prefix <balíček>` | odkud se balíček načítá |
| `ros2 pkg executables <balíček>` | programy v balíčku |

## Když to nefunguje

| Problém | Řešení |
|---|---|
| `Package 'my_turtle' not found` | v tomhle terminálu chybí `source ~/ros2-guide/ws/install/setup.bash`, nebo build neproběhl |
| `No executable found` | program chybí v `entry_points` v `setup.py`; po změně `setup.py` je potřeba `colcon build` |
| `build/`, `install/` a `log/` vznikly v `src/` nebo jinde | `colcon build` se pustil ze špatné složky. Smaž je a pusť build z `~/ros2-guide/ws` |
| změna v kódu se neprojeví | build bez `--symlink-install` kopíruje soubory, je potřeba znovu buildit; C++ je potřeba buildit vždycky |
| `ros2 pkg prefix` ukazuje jinou cestu, než čekáš | otevři nový terminál a sourcuj jen to, co chceš |
| podivné chyby po přejmenování nebo smazání balíčku | `rm -rf build install log` a postav workspace znovu |
| vidíš balíčky, které jsi neinstaloval, nebo se míchají verze ROS | distrobox přebírá proměnné prostředí z hostu. Když máš ROS nasourcovaný v `~/.bashrc` na hostu, dostane se do kontejneru i `AMENT_PREFIX_PATH`. Ověř `echo $AMENT_PREFIX_PATH` a vstupuj do kontejneru z terminálu bez ROS |

---

Předchozí: [1 · Co je ROS 2](01-co-je-ros.md) · Další: [3 · Publisher a subscriber](03-publisher-subscriber.md)
