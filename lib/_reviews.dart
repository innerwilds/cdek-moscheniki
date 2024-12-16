import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_lorem/flutter_lorem.dart';

final REVIEWS = [
  for (final i in List.generate(10, (i) => i))
    Review(
      fraudType: FraudType.values.elementAt(
        Random().nextInt(FraudType.values.length)
      ),
      id: i.toRadixString(16),
      text: lorem(paragraphs: 4, words: 600),
      resources: [],
      author: Author(
        lastName: lorem(paragraphs: 1, words: 1),
        firstName: lorem(paragraphs: 1, words: 1),
      ),
    ),
];

final class Review {
  const Review({
    required this.id,
    required this.text,
    required this.resources,
    required this.author,
    required this.fraudType,
  });

  final FraudType fraudType;
  final Author author;
  final String id;
  final String text;
  final List<Ordered<Resource>> resources;
}

enum FraudType {
  withheldRefund,
  ohMyGodShitfulService,
}

final class Author {
  const Author({
    required this.lastName,
    required this.firstName,
    this.avatar = null,
  });

  final String lastName;
  final String firstName;
  final Uint8List? avatar;
}

final class Ordered<T> {
  const Ordered(this.position, this.data);
  final int position;
  final T data;
}

final class Resource {
  const Resource(this.data, this.type);
  final Uint8List data;
  final String type;
}