# bms2mp3

Converts a BMS (or bmson) archive to 320kbps MP3. Automatically converts sound files to suitable format before processing, adds ID3 tags (with MD5) identification, and applies ReplayGain to ensure consistent song volumes.

## Prerequisites

- Node.js (v5.7)
- Ruby (v2.3)
- libsndfile
- 7zip
- SoX
- WaveGain
- LAME
- `bms-renderer` (v2.0.0-beta)
- `bmsampler` (v0.2.0)


## Usage

```
./bms2mp3 BMS_ARCHIVE.zip
```

Extract ZIP file and converts to MP3. Also works with RAR and 7z files.

```
./bms2mp3 BMS_FOLDER/
```

Converts a folder of BMS and keysounds to MP3.

__Note:__ Only one BMS file per archive is converted. The current algorithm prefers HYPER/ANOTHER chart.


## Environment Variables

- `ALBUM` The album ID3 tag to set on MP3 file.
- `MP3DIR` The output folder.
- `TEMP` The temporary folder to hold intermediate files. Point this to a RAM disk for performance boost.
