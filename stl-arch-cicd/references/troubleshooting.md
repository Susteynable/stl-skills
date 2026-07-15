# Troubleshooting

Use this for symptom-first routing.

| Symptom | Check first |
|---|---|
| sbt fails before pipeline logic matters | Tracks B and C |
| Latest Stey dependency cannot be found | Track E script path, resolver, credentials |
| Script reports an older version than Nexus release metadata | Track E parser order: prefer `<release>` over stale `<latest>` |
| Develop does not publish API jar (Package skipped) | Tracks G and H — Package must not exclude develop |
| Develop packages Docker / Artifacts drop / deploys | Tracks G, H, J, I — only Package(+Build) should run on develop |
| Deploy approval unlocks when upstream stages are skipped | Track I |
| Docker publish runs on the wrong branch | Track J |
| Helm deploy arguments drift | Track K |
| Pipeline uses image selection with AKSHosted | Track L |

Recovery flow:

1. Re-run Track A scope classification.
2. Re-check the directly responsible track and its prerequisite track.
3. Verify the final YAML or sbt evidence with explicit commands, not memory.
