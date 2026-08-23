from pathlib import Path

root = Path(r"E:\AI Work\AppPiPi\AppPiPi\Pip\iOS\Resources\Assets.xcassets\PipFrames")
template = """{
  "images" : [
    {
      "filename" : "%s.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "original"
  }
}
"""

for folder in root.glob("*.imageset"):
    (folder / "Contents.json").write_text(template % folder.stem, encoding="utf-8")
    print("updated", folder.name)
