# Ranks a user's friends based on the number of likes they gave it.
#
# Author: Andrei Muntean

require "koala"


class LikeCounter
  LIMITLESS = 100000

  def initialize(access_token)
    # Prevents an SSL certificate verification error.
    Koala.http_service.http_options = { :ssl => { :verify_mode =>
      OpenSSL::SSL::VERIFY_NONE } }

    # Connects to the Graph API.
    @graph = Koala::Facebook::API.new(access_token)
  end

  def get_friend_likes()
    # A hash in which the keys are the names of the user's friends and the values are the
    # number of likes they gave it.
    total_likes = Hash.new(0)

    # Gets this user's posts.
    posts = @graph.get_connections("me", "posts", {
      fields: "likes.limit(#{LIMITLESS})",
      limit: LIMITLESS
    })

    # Loops through posts by means of pagination.
    loop do
      posts.each do |post|
        # Skips posts which have no likes.
        next unless post.key? "likes"

        # Gets this post's likes.
        likes = post["likes"]["data"]
        
        likes.each do |like|
          # Gets the name of the user who gave this like.
          name = like["name"]

          # Records this user's like.
          total_likes[name] += 1
        end
      end

      begin
        posts = posts.next_page
      rescue
        # No more posts left.
        break
      end
    end

    # Returns the result in descending order based on the number of likes.
    total_likes.sort_by { |name, like_count| like_count }.reverse
  end
end


if __FILE__ == $0
  # You can get one from https://developers.facebook.com/tools/explorer.
  # Permissions required: "user_posts", "user_friends".
  ACCESS_TOKEN = ""

  like_counter = LikeCounter.new(ACCESS_TOKEN)
  friend_likes = like_counter.get_friend_likes()

  # Outputs the results at the specified path.
  path = ARGV.length == 1 ? ARGV[0] : "output.txt"
  output = ""
  rank = 0

  friend_likes.each do |name, like_count|
    output << "#{rank += 1}. #{name}: #{like_count} likes.\n"
  end

  File.write(path, output)
end