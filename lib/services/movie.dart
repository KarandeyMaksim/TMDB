import 'package:flutter/material.dart';
import 'package:movies_app_flutter/model/movie_details.dart';
import 'package:movies_app_flutter/model/movie_preview.dart';
import 'package:movies_app_flutter/secret/the_moviedb_api.dart' as secret;
import 'package:movies_app_flutter/utils/constants.dart';
import 'package:movies_app_flutter/utils/file_manager.dart';
import 'package:movies_app_flutter/widgets/movie_card.dart';
import 'networking.dart';

enum MoviePageType {
  popular,
  upcoming,
  top_rated,
}

class MovieModel {
  Future<dynamic> _getData({required String url}) async {
    try {
      NetworkHelper networkHelper = NetworkHelper(Uri.parse(url));
      var data = await networkHelper.getData();
      if (data == null) {
        print('❌ Ошибка: Получены пустые данные с URL: $url');
      }
      return data;
    } catch (e) {
      print('❌ Исключение при получении данных: $e');
      return null;
    }
  }

  Future<List<MovieCard>> getMovies({
    required MoviePageType moviesType,
    required Color themeColor,
  }) async {
    List<MovieCard> temp = [];
    String mTypString = moviesType.toString().split('.').last;

    final data = await _getData(
      url: '$kThemoviedbURL/$mTypString?api_key=${secret.themoviedbApi}',
    );

    if (data == null || data['results'] == null) {
      print('⚠️ Нет данных для getMovies.');
      return temp;
    }

    for (var item in data['results']) {
      temp.add(
        MovieCard(
          moviePreview: MoviePreview(
            isFavorite: await isMovieInFavorites(movieID: item["id"].toString()),
            year: (item["release_date"]?.length ?? 0) > 4
                ? item["release_date"].toString().substring(0, 4)
                : "",
            imageUrl: "$kThemoviedbImageURL${item["poster_path"]}",
            title: item["title"],
            id: item["id"].toString(),
            rating: item["vote_average"]?.toDouble() ?? 0.0,
            overview: item["overview"],
          ),
          themeColor: themeColor,
        ),
      );
    }
    return temp;
  }

  Future<List<MovieCard>> getGenreWiseMovies({
    required int genreId,
    required Color themeColor,
  }) async {
    List<MovieCard> temp = [];

    final data = await _getData(
      url:
          '$kThemovieDiscoverdbURL?api_key=${secret.themoviedbApi}&sort_by=popularity.desc&with_genres=$genreId',
    );

    if (data == null || data['results'] == null) {
      print('⚠️ Нет данных для getGenreWiseMovies.');
      return temp;
    }

    for (var item in data['results']) {
      temp.add(
        MovieCard(
          moviePreview: MoviePreview(
            isFavorite: await isMovieInFavorites(movieID: item["id"].toString()),
            year: (item["release_date"]?.length ?? 0) > 4
                ? item["release_date"].toString().substring(0, 4)
                : "",
            imageUrl: "$kThemoviedbImageURL${item["poster_path"]}",
            title: item["title"],
            id: item["id"].toString(),
            rating: item["vote_average"]?.toDouble() ?? 0.0,
            overview: item["overview"],
          ),
          themeColor: themeColor,
        ),
      );
    }
    return temp;
  }

  Future<List<MovieCard>> searchMovies({
    required String movieName,
    required Color themeColor,
  }) async {
    List<MovieCard> temp = [];

    final data = await _getData(
      url:
          '$kThemoviedbSearchURL/?api_key=${secret.themoviedbApi}&language=en-US&page=1&include_adult=false&query=$movieName',
    );

    if (data == null || data['results'] == null) {
      print('⚠️ Нет данных для поиска.');
      return temp;
    }

    for (var item in data['results']) {
      try {
        temp.add(
          MovieCard(
            moviePreview: MoviePreview(
              isFavorite: await isMovieInFavorites(movieID: item["id"].toString()),
              year: (item["release_date"]?.length ?? 0) > 4
                  ? item["release_date"].toString().substring(0, 4)
                  : "",
              imageUrl: "$kThemoviedbImageURL${item["poster_path"]}",
              title: item["title"],
              id: item["id"].toString(),
              rating: item["vote_average"]?.toDouble() ?? 0.0,
              overview: item["overview"],
            ),
            themeColor: themeColor,
          ),
        );
      } catch (e) {
        print('❌ Ошибка при парсинге фильма: $e');
        print('📦 Item: $item');
      }
    }
    return temp;
  }

  Future<MovieDetails> getMovieDetails({required String movieID}) async {
    final data = await _getData(
      url:
          '$kThemoviedbURL/$movieID?api_key=${secret.themoviedbApi}&language=en-US',
    );

    if (data == null) {
      throw Exception('Не удалось загрузить детали фильма.');
    }

    List<String> temp = [];
    List<int> genreIdsTemp = [];

    for (var item in data["genres"] ?? []) {
      temp.add(item["name"]);
      genreIdsTemp.add(item["id"]);
    }

    return MovieDetails(
      backgroundURL: "$kThemoviedbImageURL${data["backdrop_path"]}",
      title: data["title"],
      year: (data["release_date"]?.length ?? 0) > 4
          ? data["release_date"].toString().substring(0, 4)
          : "",
      isFavorite: await isMovieInFavorites(movieID: data["id"].toString()),
      rating: data["vote_average"]?.toDouble() ?? 0.0,
      genres: Map.fromIterables(temp, genreIdsTemp),
      overview: data["overview"],
    );
  }

  Future<List<MovieCard>> getFavorites({
    required Color themeColor,
    required int bottomBarIndex,
  }) async {
    List<MovieCard> temp = [];
    List<String> favoritesID = await getFavoritesID();

    for (var item in favoritesID) {
      if (item != "") {
        final data = await _getData(
          url:
              '$kThemoviedbURL/$item?api_key=${secret.themoviedbApi}&language=en-US',
        );

        if (data != null) {
          temp.add(
            MovieCard(
              contentLoadedFromPage: bottomBarIndex,
              themeColor: themeColor,
              moviePreview: MoviePreview(
                isFavorite:
                    await isMovieInFavorites(movieID: data["id"].toString()),
                year: (data["release_date"]?.length ?? 0) > 4
                    ? data["release_date"].toString().substring(0, 4)
                    : "",
                imageUrl: "$kThemoviedbImageURL${data["poster_path"]}",
                title: data["title"],
                id: data["id"].toString(),
                rating: data["vote_average"]?.toDouble() ?? 0.0,
                overview: data["overview"],
              ),
            ),
          );
        }
      }
    }
    return temp;
  }
}
