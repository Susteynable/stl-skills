# Metals / sbt Java home (hands off)

Do **not** pin a JDK. sbt and Metals use whatever the machine already has: `JAVA_HOME` if set, otherwise `java` on `PATH`.

| Do not | Why |
|---|---|
| Set `metals.javaHome` or `java.jdt.ls.java.home` | Literal paths; they go stale and trigger “Java home has been updated” |
| Add or rewrite `JAVA_HOME` in `~/.zprofile` / `~/.zshrc` | The toolbox does not own the user’s JDK |
| Rewrite `.bsp/sbt.json` `argv[0]` (Cellar, `opt`, SDKMAN, `brew --prefix`) | `sbt bspConfig` already records the current `JAVA_HOME` / `java` |

If BSP is stale, regenerate with `sbt bspConfig` (or `reset-metals.sh`) and **Metals: Restart server**. After a real JDK change, accepting the restart prompt once is enough.
