import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitopatologia_app/main.dart';
import 'package:fitopatologia_app/view/home.view.dart';
import 'package:fitopatologia_app/view/resultPage.view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;

class PreviewPage extends StatefulWidget {
  File? teste;
  PreviewPage({Key? key, this.teste}) : super(key: key);

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage>
    with SingleTickerProviderStateMixin {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  void createAlbum(File imagem) async {
    List<int> imageBytes = await imagem.readAsBytesSync();
    //String base64Image = base64Encode(imageBytes);
    print(imagem.path);
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://a096-34-125-250-175.ngrok.io/imagem'));
    request.files.add(await http.MultipartFile.fromPath('imagem', imagem.path));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print(response.body);
    Map valueMap = json.decode(response.body);
    Upload();
    Navigator.push(
      context, // error
      MaterialPageRoute(
        builder: (BuildContext context) {
          return ResultPage(
              foto: imagem, diagnostico: valueMap['PrimeiroDiagnostico']);
        },
      ),
    );

    /*
    
    var filename = imagem.path.split('/').last;
    FormData formData = new FormData.fromMap({"imagem": imagem.path});
    var response = await Dio().post('http://192.168.163.248:4000/imagem',
        data: formData,
        options: Options(receiveTimeout: 500000, sendTimeout: 500000));
    print("base64Image");
    return response.data;*/
  }

  Future<UploadTask> Upload() async {
    try {
      DateTime date = DateTime.now();
      String ref = auth.currentUser!.uid + '/img-${date.toString()}.jpg';
      var response = storage.ref(ref).putFile(widget.teste!);

      return response;
    } on FirebaseException catch (e) {
      throw Exception('Erro no upload: ${e.code}');
    }
  }

  bool uploading = false;
  late AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))
    ..repeat(reverse: true);

  late Animation<Offset> _animationVertical =
      Tween(begin: Offset(0, -10), end: Offset(0, 10)).animate(_controller);
  @override
  dispose() {
    _controller.dispose(); // you need this
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Row(
        children: [
          Expanded(
              child: Stack(
            children: [
              Positioned.fill(
                  child: Image.file(
                widget.teste!,
                fit: BoxFit.cover,
              )),
              if (uploading != true) ...[
                Container()
              ] else ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Analisando Imagem!",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold),
                      ),
                      Center(
                        child: SlideTransition(
                          position: _animationVertical,
                          child: Container(
                            width: size.width,
                            height: 50,
                            decoration: BoxDecoration(boxShadow: <BoxShadow>[
                              BoxShadow(
                                  color: Color.fromARGB(136, 9, 255, 0),
                                  blurRadius: 15.0,
                                  offset: Offset(0.0, 0.75))
                            ], color: Colors.transparent),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (uploading != true) ...[
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: Icon(
                              Icons.check,
                              color: Color.fromARGB(255, 102, 255, 0),
                              size: 30,
                            ),
                            onPressed: () {
                              setState(() {
                                uploading = true;
                                createAlbum(widget.teste!);
                              });

                              /*
                            Navigator.push(
                              context, // error
                              MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return HomePage(teste: teste);
                                },
                              ),
                            );*/
                            },
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 30,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    )
                  ] else ...[
                    Container()
                  ]
                ],
              )
            ],
          ))
        ],
      ),
    );
  }
}
