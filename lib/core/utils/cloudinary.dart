class Cloudinary {
  static String thumbnail(String url) {
    return url
        .replaceFirst('/upload/', '/upload/pg_1,w_120,q_auto,f_auto/')
        .replaceAll('.gif', '.jpg');
  }

  static String video(String url) {
    return url
        .replaceFirst('/upload/', '/upload/w_400,q_auto/')
        .replaceAll('.gif', '.mp4');
  }
}