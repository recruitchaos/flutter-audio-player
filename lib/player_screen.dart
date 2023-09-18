import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class PositionData{
  const PositionData(this.position, this.bufferedPosition, this.duration);
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

class Player extends StatefulWidget {
  const Player({super.key});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late AudioPlayer _audioPlayer;

  final _playlist = ConcatenatingAudioSource(children: [
    AudioSource.asset('assets/sample.mp3', tag: MediaItem(id: '0', title: 'Sample 1', artist: 'Unknown', artUri: Uri.parse('https://schoolofrock.imgix.net/img/news-article-hero@2x/allstarsdallas050-edit-1677013329.jpg'))),
    AudioSource.asset('assets/sample2.mp3', tag: MediaItem(id: '1', title: 'Sample 2', artist: 'Unknown', artUri: Uri.parse('https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cm9jayUyMG11c2ljfGVufDB8fDB8fHww&w=1000&q=80'))),
    AudioSource.asset('assets/sample3.mp3', tag: MediaItem(id: '2', title: 'Sample 3', artist: 'Unknown', artUri: Uri.parse('https://img.freepik.com/premium-photo/illustration-rock-guitarist-digital-art-ai_800563-5930.jpg'))),
    AudioSource.asset('assets/sample4.mp3', tag: MediaItem(id: '3', title: 'Sample 4', artist: 'Unknown', artUri: Uri.parse('https://static.vecteezy.com/system/resources/thumbnails/000/084/832/small/rock-music-symbols-vector.jpg'))),
  ]);

  Stream<PositionData> get _positionDataStream => Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
    _audioPlayer.positionStream,
    _audioPlayer.bufferedPositionStream,
    _audioPlayer.durationStream,
    (position, bufferedPosition, duration) => PositionData(position, bufferedPosition, duration ?? Duration.zero),
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(_playlist);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white,
        ),
        actions: [
          Icon(
            Icons.more_horiz,
            color: Colors.white,
          ),
          const SizedBox(
            width: 20,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<SequenceState?>(stream: _audioPlayer.sequenceStateStream, builder: (context, snapshot) {
                  final state = snapshot.data;
                  if(state?.sequence.isEmpty ?? true) {
                    return const SizedBox();
                  }
                  final metadata = state!.currentSource!.tag as MediaItem;
                  return MediaMetadata(imageUrl: metadata.artUri.toString(), title: metadata.title, artist: metadata.artist ?? '');
              }),
              const SizedBox(height: 20,),
              StreamBuilder<PositionData>(stream: _positionDataStream, builder: (context, snapshot) {
                final positionData  = snapshot.data;
                return ProgressBar(
                  barHeight: 8,
                  baseBarColor: Colors.grey.shade600,
                  bufferedBarColor: Colors.grey,
                  progressBarColor: Colors.red,
                  thumbColor: Colors.red,
                  timeLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  progress: positionData?.position ?? Duration.zero,buffered: positionData?.bufferedPosition ?? Duration.zero ,total: positionData?.duration ?? Duration.zero, onSeek: _audioPlayer.seek,);
              }),
              const SizedBox(height: 20,),
              Controls(audioPlayer: _audioPlayer)
            ],
          ),
        ),
      ),
    );
  }
}

class Controls extends StatelessWidget {
  const Controls({super.key, required this.audioPlayer});

  final audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: audioPlayer.seekToPrevious, icon: Icon(Icons.skip_previous_rounded), iconSize: 60, color: Colors.white,),
        StreamBuilder<PlayerState>(
            stream: audioPlayer.playerStateStream, builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              if(!(playing ?? false)) {
                return IconButton(onPressed: audioPlayer.play, icon: const Icon(Icons.play_arrow_rounded), color: Colors.white, iconSize: 80,);
              }
              else if (processingState != ProcessingState.completed) {
                return IconButton(onPressed: audioPlayer.pause, icon: const Icon(Icons.pause_rounded), iconSize: 80, color: Colors.white,);
              }
              return const Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white,); 
            }),
            IconButton(onPressed: audioPlayer.seekToNext, icon: Icon(Icons.skip_next_rounded), iconSize: 60, color: Colors.white,),
      ],
    );
  }
}

class MediaMetadata extends StatelessWidget {
  const MediaMetadata({super.key, required this.imageUrl, required this.title, required this.artist});
  final String imageUrl; final String title; final String artist; 

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(2, 4),
              blurRadius: 4,
            )
          ],
          borderRadius: BorderRadius.circular(10)
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: imageUrl, height: 300, width: 300, fit: BoxFit.cover,),
        ),
        ),
        const SizedBox(height: 20,),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center,
        )
      ],
    );
  }
}
