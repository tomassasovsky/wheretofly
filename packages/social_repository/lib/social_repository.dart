/// Repository for the social feed, posts, and profiles.
library;

// Re-export the model/exception types consumers need so callers depend on the
// repository rather than the data layer.
export 'package:social_api_client/social_api_client.dart'
    show
        PostMedia,
        PostMediaType,
        SocialApiException,
        SocialAuthor,
        SocialComment,
        SocialPost,
        SocialProfile;

export 'src/social_repository.dart';
