
import 'package:flutter/material.dart';

//import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_tex/flutter_tex.dart';

class QuestionBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final String questionType;
  final IconData icon;
  final bool isMath;
  final String? imgUrl;

  const QuestionBox({
    super.key,
    required this.text,
    required this.sectionName,
    required this.questionType,
    required this.icon,
    this.isMath = false,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            questionType,
            style: TextStyle(color: Colors.grey[700]),
          ),
          isMath
              ? TeXView(
                  child: TeXViewDocument(
                    '''
          <!DOCTYPE html>
          <html>
          <head>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.0/dist/katex.min.css" />
          </head>
          <body>
            ${text}
          </body>
          </html>
          ''',
                    style: TeXViewStyle(
                      //textAlign: TeXViewTextAlign.center,
                      padding: TeXViewPadding.all(10),
                    ),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          SizedBox(height: 8,),
          if (imgUrl != null && imgUrl!.isNotEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      FullScreenImageDialog(imageUrl: imgUrl!),
                );
              },
              child: Image.network(
                imgUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FullScreenImageDialog extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageDialog({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: EdgeInsets.all(5),
          minScale: 0.5,
          maxScale: 3.5,
          child: Image.network(
            imageUrl,
            height: 400,
            width: 400,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
