#!/usr/bin/env python3

from pydub import AudioSegment

from utils import *
import utils

l = logging.getLogger("pydub.converter")
l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())


def create_podcast(
    asset_intro_file,
    asset_music_segue_file,
    asset_closing_file,
    episode_intro_file,
    episode_interview_file,
    output_dir,
    output_formats=["mp3"],
):
    assert os.path.exists(output_dir) or reset_and_recreate_directory(output_dir), (
        "the directory %s does not exist " "and couldn't be created" % output_dir
    )

    files = [
        asset_intro_file,
        asset_music_segue_file,
        asset_closing_file,
        episode_intro_file,
        episode_interview_file,
    ]

    return_value = {"assets": files}

    def handle_file(f):
        assert os.path.exists(f), "the file %s does not exist" % f
        ext = os.path.splitext(f)[1][1:]
        fn = os.path.split(f)[1][: -len(ext)][:-1]
        mp3 = AudioSegment.from_file(f, format=ext)
        return mp3

    audio_segments = [handle_file(f) for f in files]

    intro = audio_segments[0]
    first_segue = audio_segments[1]
    closing = audio_segments[2]
    host_intro = audio_segments[3]
    interview = audio_segments[4]

    out = (
        intro.append(host_intro, crossfade=10 * 1000)
        .append(first_segue, crossfade=10 * 1000)
        .append(interview, crossfade=5 * 1000)
        .append(closing, crossfade=5 * 1000)
    )

    def write(ext):
        output_file_name = os.path.join(output_dir, "%s.%s" % ("podcast", ext))
        log("exporting to %s" % output_file_name)
        out.export(output_file_name, format=ext, bitrate="256k")
        assert os.path.exists(
            output_file_name
        ), "the .%s file should've been created at %s" % (ext, output_file_name)
        return_value[ext] = [output_file_name]

        log("the output directory's size is %s " % os.path.getsize(output_dir))

    for ext in output_formats:
        utils.log("about to write file of type %s" % ext)
        write(ext)

    return return_value


if __name__ == "__main__":
    import os
    import os.path

    def valid_path_env_var(k):
        assert k is not None and k in os.environ, (
            "there is no environment variable called %s" % k
        )
        v = os.path.expanduser(os.environ.get(k))
        assert os.path.exists(v), "the directory pointed to by %s does not exist" % k
        return v

    assets_dir = valid_path_env_var("PODCAST_ASSETS_DIR")
    output_dir = valid_path_env_var("PODCAST_OUTPUT_DIR")
    input_dir = valid_path_env_var("PODCAST_INPUT_DIR")
    #
    interview_wav = os.path.join(input_dir, "interview.wav")
    intro_wav = os.path.join(input_dir, "intro.wav")
    #
    asset_segue_music = os.path.join(assets_dir, "music-segue.wav")
    asset_intro = os.path.join(assets_dir, "intro.wav")
    asset_closing = os.path.join(assets_dir, "closing.wav")

    ##
    create_podcast(
        asset_intro_file=asset_intro,
        asset_music_segue_file=asset_segue_music,
        asset_closing_file=asset_closing,
        episode_intro_file=intro_wav,
        episode_interview_file=interview_wav,
        output_dir=output_dir,
        output_formats=["wav", "mp3"],
    )
