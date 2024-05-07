import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:fraction/fraction.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'package:cookitup/api_service.dart';
import 'package:flutter/src/rendering/box.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cookitup/uploader_profile.dart';

class RecipeDetailsPage extends StatefulWidget {
  final DocumentSnapshot recipeSnapshot;

  const RecipeDetailsPage({Key? key, required this.recipeSnapshot})
      : super(key: key);

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  late VideoWidget _videoWidget;
  late UploaderDetailsWidget _UploaderDetailsWidget;
  late TabViewWidget _tabViewWidget;
  late TextEditingController _commentController;

  int _servings = 0;
  String _userEmail = '';
  bool _isLiked = false;
  bool _isSaved = false;
  Map<int, bool> _isChecked = {};

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _videoWidget = VideoWidget(recipeSnapshot: widget.recipeSnapshot);
    _UploaderDetailsWidget =
        UploaderDetailsWidget(recipeSnapshot: widget.recipeSnapshot);

    _getUserEmail();
    _loadLikeStatus();
    _loadSaveStatus();
    _servings = widget.recipeSnapshot['serving'] ?? 1;
    _loadCheckboxStates();
  }

  void _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('email') ?? ''; // Fetch user's email
    });
  }

  void _loadLikeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = _userEmail;
    bool isLiked =
        prefs.getBool('$userId-${widget.recipeSnapshot.id}') ?? false;
    setState(() {
      _isLiked = isLiked;
    });
  }

  void _loadSaveStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = _userEmail;
    bool isSaved =
        prefs.getBool('$userId-${widget.recipeSnapshot.id}') ?? false;
    setState(() {
      _isSaved = isSaved;
    });
  }

  void _toggleSaveStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = _userEmail;

    setState(() {
      _isSaved = !_isSaved;
    });

    await prefs.setBool('$userId-${widget.recipeSnapshot.id}', _isSaved);

    if (_isSaved) {
      // Add the recipe ID to the user's saved recipes collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedRecipes')
          .doc(widget.recipeSnapshot.id)
          .set({
        'recipeId': widget.recipeSnapshot.id,
      });
    } else {
      // Remove the recipe ID from the user's saved recipes collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedRecipes')
          .doc(widget.recipeSnapshot.id)
          .delete();
    }
  }

  void toggleCheckbox(int index) {
    setState(() {
      _isChecked[index] = !(_isChecked[index] ?? false);
    });
    _saveCheckboxStates();
  }

  void _saveCheckboxStates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('checkboxStates', jsonEncode(_isChecked));
  }

  void _loadCheckboxStates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? checkboxStatesJson = prefs.getString('checkboxStates');
    if (checkboxStatesJson != null && checkboxStatesJson.isNotEmpty) {
      Map<String, dynamic> decodedMap = jsonDecode(checkboxStatesJson);
      setState(() {
        _isChecked =
            decodedMap.map((key, value) => MapEntry(int.parse(key), value));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _tabViewWidget = TabViewWidget(
      recipeSnapshot: widget.recipeSnapshot,
      servings: _servings,
      currentPageIndex: _currentPageIndex,
      updateServings: _updateServings,
      updateCurrentPageIndex: _updateCurrentPageIndex,
      isChecked: _isChecked,
      toggleCheckbox: toggleCheckbox,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFD1E7D2),
      body: Stack(
        children: [
          ListView(
            children: [
              _videoWidget,
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.recipeSnapshot[
                            'title'], // Display recipe title here
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _isLiked
                          ? const Icon(Icons.favorite,color: Colors.red)
                          : const Icon(Icons.favorite_outline),
                      onPressed: () async {
                        setState(() {
                          _isLiked = !_isLiked;
                        });

                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setBool(widget.recipeSnapshot.id, _isLiked);

                        DocumentReference recipeRef = FirebaseFirestore.instance
                            .collection('recipe')
                            .doc(widget.recipeSnapshot.id);

                        if (_isLiked) {
                          await recipeRef
                              .update({'likes': FieldValue.increment(1)});
                        } else {
                          await recipeRef
                              .update({'likes': FieldValue.increment(-1)});
                        }
                      },
                    ),
                    IconButton(
                      icon: _isSaved
                          ? const Icon(Icons.bookmark)
                          : const Icon(Icons.bookmark_border),
                      onPressed: _toggleSaveStatus,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        shareRecipe(context, widget.recipeSnapshot);
                      },
                    ),
                  ],
                ),
              ),
              _UploaderDetailsWidget,
              _tabViewWidget,
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.0,
            left: 8.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: const Color.fromARGB(
                  255, 0, 0, 0), // Change the color of the arrow here
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void shareRecipe(BuildContext context, DocumentSnapshot recipeSnapshot) {
    final String title = recipeSnapshot['title'];
    final String recipeLink =
        'https://your-recipe-website.com/recipes/${recipeSnapshot.id}';
    final String recipeText = 'Check out this recipe: $title\n\n$recipeLink';

    // Share the recipe text
    Share.share(
      recipeText,
      subject: title,
    );

    // Launch the recipe link
    launchUrl(recipeLink as Uri);
  }

  void _updateServings(int newServings) {
    setState(() {
      _servings = newServings;
    });
  }

  int _currentPageIndex = 0;
  void _updateCurrentPageIndex(int newIndex) {
    setState(() {
      _currentPageIndex = newIndex;
    });
  }
}

class VideoWidget extends StatefulWidget {
  final DocumentSnapshot recipeSnapshot;

  const VideoWidget({Key? key, required this.recipeSnapshot}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}
late VideoPlayerController _videoPlayerController;
class _VideoWidgetState extends State<VideoWidget> {
late ChewieController _chewieController;
bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoPlayerController.pause();
    _videoPlayerController.dispose();
    _chewieController.dispose();
    _chewieController.pause();
    super.dispose();
  }

  void _initializeVideo() async {
    try {
      String videoUrl = await getVideoUrl(widget.recipeSnapshot['video']);
      // ignore: deprecated_member_use
      _videoPlayerController = VideoPlayerController.network(videoUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        aspectRatio: 4 / 3,
        useRootNavigator: true,
        
      );
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          print(
              "Video player error: ${_videoPlayerController.value.errorDescription}");
        }
      });

      setState(() {
        _isVideoLoading = false;
      });
    } catch (e) {
      print('error initializing video:$e');
    }
  }

  Future<String> getVideoUrl(String videoName) async {
    final ref = FirebaseStorage.instance.ref().child(videoName);
    final url = await ref.getDownloadURL();
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return _isVideoLoading
        ? const AspectRatio(
            aspectRatio: 4 / 3, // Set a default aspect ratio while loading
            child: Center(child: CircularProgressIndicator()),
          )
        : AspectRatio(
            aspectRatio: _chewieController.aspectRatio ?? 16 / 9,
            child: Chewie(
              controller: _chewieController,
            ),
          );
  }
}

class UploaderDetailsWidget extends StatelessWidget {
  final DocumentSnapshot<Object?> recipeSnapshot;

  const UploaderDetailsWidget({Key? key, required this.recipeSnapshot})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Object?>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(recipeSnapshot['userid'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD1E7D2)),
            strokeWidth: 2.0,
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('User not found');
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String username = userData['name'] ?? 'Unknown User';
        String profilePicture = userData['profilepic'] ?? '';
        //String email=userData['email']?? '';

        return GestureDetector(
          onTap: () {
            _videoPlayerController.pause();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UploaderProfilePage(email: recipeSnapshot['userid']),
              ),
            );
          },
          child: Row(
            children: [
              FutureBuilder(
                future: FirebaseStorageService.getImageUrl(profilePicture),
                builder: (context, urlSnapshot) {
                  if (urlSnapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFD1E7D2)),
                      strokeWidth: 2.0,
                    );
                  } else if (urlSnapshot.hasError) {
                    return Text('Error: ${urlSnapshot.error}');
                  } else {
                    var url = urlSnapshot.data as String;
                    return CircleAvatar(
                      backgroundImage: NetworkImage(url),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: ListTile(
                    title: Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [],
                    ),
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

class TabViewWidget extends StatelessWidget {
  final DocumentSnapshot recipeSnapshot;
  final int servings;
  final int currentPageIndex;
  final Function(int) updateServings;
  final Function(int) updateCurrentPageIndex;
  final TextEditingController _commentController = TextEditingController();
  final Map<int, bool> isChecked; // Receive _isChecked map from parent
  final Function(int) toggleCheckbox; //

  TabViewWidget({
    Key? key,
    required this.recipeSnapshot,
    required this.servings,
    required this.currentPageIndex,
    required this.updateServings,
    required this.updateCurrentPageIndex,
    required this.isChecked,
    required this.toggleCheckbox,
  }) : super(key: key);

  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 6.0), // Adjust as needed
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: Colors.transparent, // Change color if needed
              borderRadius:
                  BorderRadius.circular(10.0), // Optional: add rounded corners
            ),
            child: const TabBar(
              tabs: [
                Tab(text: 'Ingredients'),
                Tab(text: 'Start Cook'),
                Tab(text: 'Comments'),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 10.0), // Adjust as needed
              child: TabBarView(
                children: [
                  _buildIngredientsTab(),
                  _buildStartCookTab(),
                  _buildCommentsTab(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    final recipeSnapshot = this.recipeSnapshot;
    Future<Map<String, dynamic>> nutrientInfoFuture =
        fetchNutrientInfo(recipeSnapshot.id);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipe')
                  .doc(recipeSnapshot.id)
                  .collection('ingredients')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No ingredients found');
                }

                List<QueryDocumentSnapshot> ingredients = snapshot.data!.docs;
                int totalIngredients = ingredients.length;
                num originalServings = recipeSnapshot['serving'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(text: 'Nutrient Information '),
                        TextSpan(text: '(for $originalServings serving)', style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 75, 74, 74))),
                      ],
                    ),
                  ),*/

                    const SizedBox(height: 10),
                    FutureBuilder<Map<String, dynamic>>(
                      future: nutrientInfoFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Fetching nutrient info... ');
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('No nutrient info found');
                        }

                        Map<String, dynamic> nutrientInfo = snapshot.data!;
                        double caloriesPer100g =
                            nutrientInfo['ENERC_KCAL']?['quantity'] ?? 0.0;
                        double servingSize =
                            100.0; // Example serving size in grams, adjust as needed
                        double caloriesPerServing = calculateCaloriesPerServing(
                            caloriesPer100g, servingSize);
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(155, 117, 167, 126),
                                offset: Offset(
                                  5.0,
                                  5.0,
                                ),
                                blurRadius: 8.0,
                                spreadRadius: 1.5,
                              ), //BoxShadow
                              BoxShadow(
                                color: Color(0xFFD2E7D2),
                                offset: Offset(0.0, 0.0),
                                blurRadius: 0.0,
                                spreadRadius: 0.0,
                              ), //BoxShadow
                            ],
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Theme(
                            data: ThemeData(
                              dividerColor: Colors
                                  .transparent, // Remove the divider color
                            ),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets
                                  .zero, // Remove the default tile padding
                              title: Text(
                                '  Calories: ${caloriesPerServing.toStringAsFixed(2)} kcal',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.arrow_drop_down),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ListView(
                                        shrinkWrap: true,
                                        children: [
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            visualDensity: const VisualDensity(
                                                horizontal: -4,
                                                vertical:
                                                    -4), // Decrease the spacing
                                            leading: const Icon(
                                                Icons.fiber_manual_record,
                                                color: Color.fromARGB(
                                                    255, 84, 88, 84),
                                                size: 10.0),
                                            title: Text(
                                                'Fat: ${nutrientInfo['FAT']?['quantity']?.toStringAsFixed(2) ?? 'N/A'} ${nutrientInfo['FAT']?['unit'] ?? ''}'),
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            visualDensity: const VisualDensity(
                                                horizontal: -4,
                                                vertical:
                                                    -4), // Decrease the spacing
                                            leading: const Icon(
                                                Icons.fiber_manual_record,
                                                color: Color.fromARGB(
                                                    255, 84, 88, 84),
                                                size: 10.0),
                                            title: Text(
                                                'Sugar: ${nutrientInfo['SUGAR']?['quantity']?.toStringAsFixed(2) ?? 'N/A'} ${nutrientInfo['SUGAR']?['unit'] ?? ''}'),
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            visualDensity: const VisualDensity(
                                                horizontal: -4,
                                                vertical:
                                                    -4), // Decrease the spacing
                                            leading: const Icon(
                                                Icons.fiber_manual_record,
                                                color: Color.fromARGB(
                                                    255, 84, 88, 84),
                                                size: 10.0),
                                            title: Text(
                                                'Carbohydrate: ${nutrientInfo['CHOCDF.net']?['quantity']?.toStringAsFixed(2) ?? 'N/A'} ${nutrientInfo['CHOCDF.net']?['unit'] ?? ''}'),
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            visualDensity: const VisualDensity(
                                                horizontal: -4,
                                                vertical:
                                                    -4), // Decrease the spacing
                                            leading: const Icon(
                                                Icons.fiber_manual_record,
                                                color: Color.fromARGB(
                                                    255, 84, 88, 84),
                                                size: 10.0),
                                            title: Text(
                                                'Fiber: ${nutrientInfo['FIBTG']?['quantity']?.toStringAsFixed(2) ?? 'N/A'} ${nutrientInfo['FIBTG']?['unit'] ?? ''}'),
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            visualDensity: const VisualDensity(
                                                horizontal: -4,
                                                vertical:
                                                    -4), // Decrease the spacing
                                            leading: const Icon(
                                                Icons.fiber_manual_record,
                                                color: Color.fromARGB(
                                                    255, 84, 88, 84),
                                                size: 10.0),
                                            title: Text(
                                                'Protein: ${nutrientInfo['PROCNT']?['quantity']?.toStringAsFixed(2) ?? 'N/A'} ${nutrientInfo['PROCNT']?['unit'] ?? ''}'),
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            visualDensity: const VisualDensity(
                                                horizontal: -4,
                                                vertical:
                                                    -4), // Decrease the spacing
                                            leading: const Icon(
                                                Icons.fiber_manual_record,
                                                color: Color.fromARGB(
                                                    255, 84, 88, 84),
                                                size: 10.0),
                                            title: Text(
                                                'Cholesterol: ${nutrientInfo['CHOLE']?['quantity']?.toStringAsFixed(2) ?? 'N/A'} ${nutrientInfo['CHOLE']?['unit'] ?? ''}'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      color: const Color.fromRGBO(210, 231, 210,
                          100), // Set the color for the serving quantity box

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ingredients- $totalIngredients',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 10, 7, 7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(155, 117, 167, 126),
                            offset: Offset(
                              5.0,
                              5.0,
                            ),
                            blurRadius: 8.0,
                            spreadRadius: 1.5,
                          ), //BoxShadow
                          BoxShadow(
                            color: Color(0xFFD2E7D2),
                            offset: Offset(0.0, 0.0),
                            blurRadius: 0.0,
                            spreadRadius: 0.0,
                          ), //BoxShadow
                        ],
                        border: Border.all(color: Colors.transparent),
                      ), // Set the color for the ingredient list box
                      padding: const EdgeInsets.all(13.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                // Wrap the text in a Flexible widget
                                child: Text(
                                  'Quantity for $servings Serving',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 21, 12, 12),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (servings > 1) {
                                        updateServings(servings - 1);
                                      }
                                    },
                                  ),
                                  const Text(
                                    '|',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      updateServings(servings + 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: ingredients.length,
                            itemBuilder: (context, index) {
                              String name = ingredients[index].id;
                              String originalQuantity =
                                  ingredients[index]['quantity'];
                              num originalServings = recipeSnapshot['serving'];
                              String unit = _getUnit(ingredients[index]);
                              Fraction qty = _parseQuantity(originalQuantity);
                              Fraction ratio = Fraction.fromDouble(servings
                                      .toDouble() /
                                  originalServings
                                      .toDouble()); // Convert double ratio to Fraction
                              Fraction adjustedQuantity = qty * ratio;

                              return ListTile(
                                title: Text(
                                  '$name : ${_formatQuantity(adjustedQuantity)} $unit',
                                ),
                                trailing: Checkbox(
                                  value: isChecked[index] ?? false,
                                  onChanged: (value) {
                                    toggleCheckbox(index);
                                    if (value == true) {
                                      // Add ingredient to selectedIngredients in Firestore
                                      _addIngredientToSelectedIngredients(name);
                                    } else {
                                      // Remove ingredient from selectedIngredients in Firestore
                                      _removeIngredientFromSelectedIngredients(
                                          name);
                                    }
                                  },
                                  activeColor: Colors.transparent,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Fraction _parseQuantity(String quantity) {
    // Implement your logic to parse the quantity string into a Fraction
    // For example, if the quantity is in the format 'x y/z', you can do:
    List<String> parts = quantity.split(' ');
    if (parts.length == 2) {
      int whole = int.parse(parts[0]);
      Fraction fraction = Fraction.fromString(parts[1]);
      return Fraction(whole) + fraction;
    } else {
      return Fraction.fromString(quantity);
    }
  }

  String _formatQuantity(Fraction quantity) {
    if (quantity.numerator == 0) {
      return '0'; // Return '0' for zero quantities
    } else if (quantity.numerator < quantity.denominator) {
      int gcd = _gcd(quantity.numerator, quantity.denominator);
    int numerator = quantity.numerator ~/ gcd;
    int denominator = quantity.denominator ~/ gcd;
    return '${numerator}/${denominator}';  // Return proper fractions as is
    } else {
      int whole = quantity.numerator ~/ quantity.denominator;
      int remainderNumerator = quantity.numerator % quantity.denominator;

      // Reduce the fraction if possible
      int gcd = _gcd(remainderNumerator, quantity.denominator);
      remainderNumerator ~/= gcd;
      int denominator = quantity.denominator ~/ gcd;

      if (remainderNumerator == 0) {
        return '$whole'; // Return whole number if there's no remainder
      } else {
        return '$whole ${remainderNumerator}/${denominator}'; // Return reduced mixed fraction
      }
    }
  }

// Helper function to calculate the greatest common divisor (GCD)
  int _gcd(int a, int b) {
    while (b != 0) {
      var temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  String _getUnit(QueryDocumentSnapshot ingredient) {
    final data = ingredient.data() as Map<String, dynamic>?;
    return data != null && data.containsKey('unit')
        ? data['unit'] as String
        : '';
  }

  void _addIngredientToSelectedIngredients(String ingredientName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('email');
    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      Set<dynamic> selectedIngredients = Set.from(
          userDoc['selectedIngredients'] ??
              []); // Existing selected ingredients as a Set

      // Trim the ingredient name to remove leading and trailing white spaces
      ingredientName = ingredientName.trim();

      if (ingredientName.isNotEmpty &&
          !selectedIngredients.contains(ingredientName)) {
        // Add the ingredient only if it's not already present and not an empty string
        selectedIngredients.add(ingredientName);

        // Update the selectedIngredients field in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'selectedIngredients': selectedIngredients
              .toList(), // Convert Set back to List before updating
        });
      }
    }
  }

  void _removeIngredientFromSelectedIngredients(String ingredientName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('email');
    if (userId != null) {
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'selectedIngredients': FieldValue.arrayRemove([ingredientName])
      });
    }
  }

  Widget _buildStartCookTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipe')
          .doc(recipeSnapshot.id)
          .collection('steps')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD1E7D2)),
            strokeWidth: 2.0,
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No steps found');
        }

        List<QueryDocumentSnapshot> steps = snapshot.data!.docs;
        if (currentPageIndex >= steps.length) {
          updateCurrentPageIndex(steps.length - 1);
        }

        String currentStep =
            steps.isNotEmpty ? steps[currentPageIndex]['description'] : '';

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Step ${currentPageIndex + 1}:',
                  style: const TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      if (currentPageIndex > 0) {
                        updateCurrentPageIndex(currentPageIndex - 1);
                      }
                    },
                  ),
                  Expanded(
                    child: SizedBox(
                      height:
                          300.0, // Set the desired height for the description box
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            const BoxShadow(
                              color: Color.fromARGB(155, 117, 167, 126),
                              offset: Offset(
                                2.0,
                                5.0,
                              ),
                              blurRadius: 8.0,
                              spreadRadius: 1.5,
                            ), //BoxShadow
                            const BoxShadow(
                              color: Color(0xFFD2E7D2),
                              offset: Offset(0.0, 0.0),
                              blurRadius: 0.0,
                              spreadRadius: 0.0,
                            ), //BoxShadow
                          ],
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            currentStep,
                            style: const TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      if (currentPageIndex < steps.length - 1) {
                        updateCurrentPageIndex(currentPageIndex + 1);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('recipe')
                .doc(recipeSnapshot.id)
                .collection('comments')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 209, 231, 210)),
                  strokeWidth: 2.0,
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No comments yet'));
              }

              List<QueryDocumentSnapshot> comments = snapshot.data!.docs;
              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  var comment = comments[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(comment['userid'])
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFD1E7D2)),
                          strokeWidth: 2.0,
                        );
                      }
                      if (userSnapshot.hasError) {
                        return Text('Error: ${userSnapshot.error}');
                      }
                      if (!userSnapshot.hasData || userSnapshot.data == null) {
                        return const SizedBox(); // Placeholder for loading state
                      }

                      var userData = userSnapshot.data!;
                      String username = userData['name'] ?? 'Unknown User';
                      String profilePicture = userData['profilepic'] ?? '';

                      return ListTile(
                        leading: FutureBuilder(
                          future: FirebaseStorageService.getImageUrl(
                              profilePicture), // Use the FirebaseStorageService to get the image URL
                          builder: (context, urlSnapshot) {
                            if (urlSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFD1E7D2)),
                                strokeWidth: 2.0,
                              );
                            } else if (urlSnapshot.hasError) {
                              return Text('Error: ${urlSnapshot.error}');
                            } else {
                              var url = urlSnapshot.data as String;
                              return CircleAvatar(
                                backgroundImage: NetworkImage(url),
                              );
                            }
                          },
                        ),
                        title: Text(comment['comment']),
                        subtitle: Text(username),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              FutureBuilder(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD1E7D2),
                      ),
                      strokeWidth: 2.0,
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    SharedPreferences prefs =
                        snapshot.data as SharedPreferences;
                    String currentUserEmail = prefs.getString('email') ?? '';

                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(
                              currentUserEmail) // Fetch user document by document ID (which is the email)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFD1E7D2),
                            ),
                            strokeWidth: 2.0,
                          );
                        } else if (userSnapshot.hasError) {
                          return Text('Error: ${userSnapshot.error}');
                        } else if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          // Handle case where user document is not found
                          return const Text('User not found');
                        } else {
                          var userData = userSnapshot.data!.data();
                          String currentUserProfilePic = userData?[
                                  'profilepic'] ??
                              ''; // Assuming 'profilepic' field exists in your user document

                          return FutureBuilder(
                            future: FirebaseStorageService.getImageUrl(
                                currentUserProfilePic),
                            builder: (context, urlSnapshot) {
                              if (urlSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFD1E7D2),
                                  ),
                                  strokeWidth: 2.0,
                                );
                              } else if (urlSnapshot.hasError) {
                                return Text('Error: ${urlSnapshot.error}');
                              } else {
                                var url = urlSnapshot.data as String;
                                return CircleAvatar(
                                  backgroundImage: NetworkImage(url),
                                );
                              }
                            },
                          );
                        }
                      },
                    );
                  }
                },
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Write your comment...',
                              border: InputBorder.none,
                            ),
                            // You can use a TextEditingController to get the comment text
                            controller: _commentController,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? userId = prefs.getString('email');

                          if (userId != null) {
                            // Check if the comment field is not empty
                            if (_commentController.text.isNotEmpty) {
                              try {
                                // Post comment to Firestore
                                await FirebaseFirestore.instance
                                    .collection('recipe')
                                    .doc(recipeSnapshot.id)
                                    .collection('comments')
                                    .add({
                                  'comment': _commentController.text,
                                  'userid': userId,
                                });

                                // Optionally, you can clear the comment input field after submission
                                _commentController.clear();
                              } catch (e) {
                                print('Error posting comment: $e');
                                // Handle error here
                              }
                            } else {
                              // Optionally, you can inform the user that the comment field is empty
                              print('Please enter a comment.');
                            }
                          } else {
                            // If user ID is not found in SharedPreferences, handle the situation accordingly
                            print(
                                'User ID not found. Unable to submit comment.');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FirebaseStorageService {
  static Future<String> getImageUrl(String? imageName) async {
    if (imageName == null || imageName.isEmpty) {
      // Return a placeholder image URL or handle the case as needed
      return ''; // For example, return a default placeholder image URL
    }
    final ref = FirebaseStorage.instance.ref().child(imageName);
    try {
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Handle errors, such as image not found
      print('Error fetching image URL: $e');
      return ''; // Return a default placeholder image URL or handle the error case as needed
    }
  }
}

Future<Map<String, dynamic>> fetchNutrientInfo(String recipeId) async {
  try {
    // Query Firestore to get the ingredients subcollection of the specified recipe
    QuerySnapshot ingredientsSnapshot = await FirebaseFirestore.instance
        .collection('recipe')
        .doc(recipeId)
        .collection('ingredients')
        .get();

    if (ingredientsSnapshot.docs.isEmpty) {
      // Return an empty map if no ingredients found
      return {};
    }

    // Extract ingredient names, quantities, and units from the Firestore query snapshot
    List<Map<String, dynamic>> ingredientsList =
        ingredientsSnapshot.docs.map((ingredient) {
      return {
        'name': ingredient.id,
        'quantity': (ingredient.data() as Map<String, dynamic>)[
            'quantity'], // Explicit cast to Map<String, dynamic>
        'unit': (ingredient.data() as Map<String, dynamic>)[
            'unit'] // Explicit cast to Map<String, dynamic>
      };
    }).toList();

    // Construct the ingredient query string
    String ingredientQuery = ingredientsList.map((ingredient) {
      return '${ingredient['quantity']} ${ingredient['unit']} ${ingredient['name']}';
    }).join('\n');

    // Replace 'YOUR_APP_ID' and 'YOUR_APP_KEY' with your actual Edamam API credentials
    String apiUrl =
        'https://api.edamam.com/api/nutrition-data?ingr=$ingredientQuery&app_id=dcb94add&app_key=935a5604e2d0761de388fab38458154f';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = json.decode(response.body);

      // Extract the nutrient info from the response and return it
      // Adjust this part according to the structure of the response from Edamam API
      Map<String, dynamic> nutrientInfo = {
        'calories': responseData['calories'],
        'totalNutrients': responseData['totalNutrients'],
        'fat': responseData['totalNutrients']['FAT'],
        'sugar': responseData['totalNutrients']['SUGAR'],
        'carbohydrate(net)': responseData['totalNutrients']['CHOCDF.net'],
        'fiber': responseData['totalNutrients']['FIBTG'],
        'protein': responseData['totalNutrients']['PROCNT'],
        'cholestrol': responseData['totalNutrients']['CHOLE'],

        // Add more nutrient data as needed
      };

      return responseData['totalNutrients'];
    } else {
      throw Exception('Failed to fetch nutrient info');
    }
  } catch (e) {
    print('Error fetching nutrient info: $e');
    throw Exception('Failed to fetch nutrient info');
  }
}

double calculateCaloriesPerServing(
    double caloriesPer100g, double servingSizeInGrams) {
  return (caloriesPer100g * servingSizeInGrams) / 100.0;
}