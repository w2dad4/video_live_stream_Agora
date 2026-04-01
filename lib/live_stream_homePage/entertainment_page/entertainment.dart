import 'package:flutter/material.dart';
import 'package:video_live_stream/tool/color.dart';
import 'package:video_live_stream/tool/index.dart';

class VideoEnterinmentPage extends StatefulWidget {
  const VideoEnterinmentPage({super.key});
  @override
  State<VideoEnterinmentPage> createState() => VideoEnterinmentPageState();
}

class VideoEnterinmentPageState extends State<VideoEnterinmentPage> {
  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding - 5),
      itemCount: VideoIndex.gameList.length,
      itemBuilder: (context, index) {
        final item = VideoIndex.gameList[index];
        return Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: 70,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: ColorState.color6),
                  child: Image.network(
                    item['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => Image.asset('assets/image/002.png', fit: BoxFit.cover),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']!,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Divider(color: Colors.black, thickness: 0.5, height: 5),
                      Text(item['desc']!, style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
