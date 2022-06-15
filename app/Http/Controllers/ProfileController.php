<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request; 
use Illuminate\Support\Facades\Auth;
use App\Models\User;

use App\Models\Comment;
use App\Models\UserComments;
use App\Models\LikedPost;
use App\Models\Post;

class ProfileController extends Controller
{
    public function posts($id)
    {
      $data = User::with('following')->with('followers')->find($id);
      $posts = Post::with('author')->with('tags')->with('comments')->where('author_id', 1)->get();

      return view('pages.profile', ['profileData' => $data, 'posts' => $posts, 'tab' => 'posts']);
    }

    public function comments($id)
    {
      $data = User::with('following')->with('followers')->find($id);
      $comments = UserComments::where('user_id', $id)->get();

      $res_comments = [];
      foreach ($comments as $item) {
          $comment = Comment::with('comment_author')->find($item->comment_id);
          $res_comments = array_merge($res_comments, [$comment]); 
      }

      return view('pages.profile', ['profileData' => $data, 'comments' => $res_comments, 'tab' => 'comments']);
    }

    public function likes($id)
    {
      $data = User::with('following')->with('followers')->find($id);
      $likes = LikedPost::where('user_id', $id)->get();

      $res_liked_posts = [];
      foreach ($likes as $like) {
        $post = Post::with('author')->with('tags')->with('comments')->find($like->post_id);
        $res_liked_posts = array_merge($res_liked_posts, [$post]);
      }

      return view('pages.profile', ['profileData' => $data, 'posts' => $res_liked_posts, 'tab' => 'likes']);
    }
}