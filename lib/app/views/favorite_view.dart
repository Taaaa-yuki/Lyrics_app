import 'package:flutter/material.dart';
import 'package:lyrics_app/app/models/favorite_model.dart';
import 'package:lyrics_app/app/services/firebase_service.dart';
import 'package:lyrics_app/app/widgets/appbar.dart';
import 'package:lyrics_app/app/widgets/drawer.dart';
import 'package:lyrics_app/app/widgets/error_popup.dart';
import 'package:lyrics_app/app/constants/error_messages.dart';
import 'package:lyrics_app/app/widgets/floatingactionbutton.dart';
import 'package:lyrics_app/app/widgets/loading.dart';

class FavoriteView extends StatefulWidget {
  const FavoriteView({Key? key}) : super(key: key);

  @override
  State<FavoriteView> createState() => _FavoriteViewState();
}

class _FavoriteViewState extends State<FavoriteView> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Album>> _albumsFuture;

  @override
  void initState() {
    super.initState();
    _albumsFuture = _firebaseService.getAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LyricsAppBar(title: "Favorite Albums"),
      drawer: const LyricsDrawer(),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _albumsFuture = _firebaseService.getAlbums();
            });
          },
          child: FutureBuilder<List<Album>>(
            future: _albumsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Loading());
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final favoriteAlbums = snapshot.data!;

              return ListView.builder(
                itemCount: favoriteAlbums.length + 1,
                itemBuilder: (context, index) {
                  if (index == favoriteAlbums.length) {
                    return const SizedBox(height: 80);
                  }
                  final album = favoriteAlbums[index];

                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(album.imageUrl)),
                        ),
                      ),
                      title: Text(album.title),
                      subtitle: Text(album.artist),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  TextEditingController titleController =
                                      TextEditingController(text: album.title);
                                  TextEditingController artistController =
                                      TextEditingController(text: album.artist);
                                  TextEditingController imageUrlController =
                                      TextEditingController(
                                          text: album.imageUrl);
                                  return AlertDialog(
                                    title: const Text('Edit Album'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: titleController,
                                            decoration: const InputDecoration(
                                                labelText: 'Title'),
                                          ),
                                          TextField(
                                            controller: artistController,
                                            decoration: const InputDecoration(
                                                labelText: 'Artist'),
                                          ),
                                          TextField(
                                            controller: imageUrlController,
                                            decoration: const InputDecoration(
                                                labelText: 'Image URL'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Save'),
                                        onPressed: () async {
                                          Album updatedAlbum = Album(
                                            id: album.id,
                                            title: titleController.text,
                                            artist: artistController.text,
                                            imageUrl: imageUrlController.text,
                                          );
                                          if (updatedAlbum.title.isNotEmpty &&
                                              updatedAlbum.artist.isNotEmpty &&
                                              updatedAlbum
                                                  .imageUrl.isNotEmpty) {
                                            await _firebaseService
                                                .updateAlbum(updatedAlbum);
                                            setState(() {
                                              _albumsFuture =
                                                  _firebaseService.getAlbums();
                                            });
                                            if (!mounted) return;
                                            Navigator.of(context).pop();
                                          } else {
                                            ErrorPopup.show(context,
                                                ErrorMessages.albumEmpty.text);
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await _firebaseService.deleteAlbum(album.id);
                              setState(() {
                                _albumsFuture = _firebaseService.getAlbums();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        firebaseService: _firebaseService,
        onAddPressed: () async {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              TextEditingController titleController = TextEditingController();
              TextEditingController artistController = TextEditingController();
              TextEditingController imageUrlController =
                  TextEditingController();

              return AlertDialog(
                title: const Text('Add Album'),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      TextField(
                        controller: artistController,
                        decoration: const InputDecoration(labelText: 'Artist'),
                      ),
                      TextField(
                        controller: imageUrlController,
                        decoration:
                            const InputDecoration(labelText: 'Image URL'),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Save'),
                    onPressed: () async {
                      Album newAlbum = Album(
                        id: '',
                        title: titleController.text,
                        artist: artistController.text,
                        imageUrl: imageUrlController.text,
                      );
                      if(newAlbum.title.isNotEmpty && newAlbum.artist.isNotEmpty && newAlbum.imageUrl.isNotEmpty){
                        await _firebaseService.addAlbum(newAlbum);
                        setState(() {
                          _albumsFuture = _firebaseService.getAlbums();
                        });
                        if (!mounted) return;
                        Navigator.of(context).pop();
                    } else {
                        ErrorPopup.show(context, ErrorMessages.albumEmpty.text);
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
