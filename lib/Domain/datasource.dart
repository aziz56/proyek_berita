import 'dart:convert';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsDataSource {
  final String apiKey = '4b397c0b925c48649a61b00c6ab69622';
  final String baseUrl = 'https://newsapi.org/v2';

  Future<List<Article>> getArticles(String keyword) async {
    final url = '$baseUrl/everything?q=$keyword&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final articlesData = jsonData['articles'] as List<dynamic>;

      final articles = articlesData.map((data) {
        final articleUrl = data['url'] as String;
        final articleTitle = data['title'] as String;
        final articleDescription = data['description'] as String;
        final articleImage = data['urlToImage'] as String;

        return Article(
          url: articleUrl,
          title: articleTitle,
          description: articleDescription,
          articleImage: articleImage,
        );
      }).toList();

      return articles;
    } else {
      throw Exception('Failed to load articles');
    }
  }
}

class Article {
  final String title;
  final String description;
  final String url;
  final String articleImage;

  Article(
      {required this.title,
      required this.description,
      required this.url,
      required this.articleImage});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      description: json['description'],
      url: json['url'],
      articleImage: json['urlToImage'],
    );
  }
}

class NewsRepository {
  var _dataSource = NewsDataSource();
  Future<List<Article>> getArticles(String keyword) async {
    try {
      return await _dataSource.getArticles(keyword);
    } catch (e) {
      throw Exception('Failed to load articles: $e');
    }
  }
}

class GetArticlesUseCase {
  var _repository = NewsRepository();

  Future<List<Article>> execute(String keyword) async {
    try {
      return await _repository.getArticles(keyword);
    } catch (e) {
      throw Exception('Failed to get articles: $e');
    }
  }
}

class NewsProvider with ChangeNotifier {
  final _useCase = GetArticlesUseCase();
  List<Article> _articles = [];
  List<Article> get articles => _articles;
    Future<void> searchArticles(String keyword) async {
      _articles = await _useCase.execute(keyword);
      notifyListeners();
    }
  }

class FavoriteView extends StatelessWidget {
  const FavoriteView({super.key});

  @override
  Widget build(BuildContext context) {
    Box<Map> bookmarkBox = Hive.box<Map>('favorites');
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite News'),
      ),
      body: BookmarkList(),
    );
  }
}

class BookmarkList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Box<Map> bookmarkBox = Hive.box<Map>('favorites');

    return ValueListenableBuilder(
      valueListenable: bookmarkBox.listenable(),
      builder: (context, Box<Map> box, _) {
        return ListView.builder(
          itemCount: box.length,
          itemBuilder: (context, index) {
            Map bookmark = box.getAt(index)!;
            return ListTile(
              title: Text(bookmark['title']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WebViewContainer(url: bookmark['url']),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var newsProvider = Provider.of<NewsProvider>(context);

    return Scaffold(
      body: Container(
        child: FutureBuilder(
          future: newsProvider.searchArticles('berita'),
          builder: (context, snapshot) {
            return ListView.builder(
              itemCount: newsProvider._articles.length,
              itemBuilder: (context, index) {
                return CardNews(
                    imagePath: newsProvider._articles[index].articleImage,
                    title: newsProvider._articles[index].title,
                    url: newsProvider._articles[index].url);
              },
            );
          },
        ),
      ),
    );
  }
}

class NewsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text('Berita News'),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.home), text: 'Home'),
                Tab(icon: Icon(Icons.star), text: 'Favorite'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              HomeView(),
              FavoriteView(),
            ],
          ),
        ),
      ),
    );
  }
}

class CardNews extends StatelessWidget {
  final String imagePath;
  final String title;
  final String url;

  CardNews({required this.imagePath, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    Hive.openBox<Map>('favorites');
    return Card(
      elevation: 5, // You can adjust the elevation as needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WebViewContainer(url: url)));
                },
                child: Image.network(
                  imagePath,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {
                    Hive.box<Map>('favorites')
                        .add({'title': title, 'url': url});
                  },
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 52,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WebViewContainer extends StatelessWidget {
  final String url;

  WebViewContainer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BSI News'),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
