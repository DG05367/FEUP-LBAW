<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request; 
use Illuminate\Support\Facades\Auth;
use App\Models\Post;
use App\Models\Tag;
use App\Models\Comment;

class PostController extends Controller
{
    public function index()
    {
      $data = Post::with('author')->with('tags')->with('comments')->paginate(10);
      $tags = Tag::get();
      
      // return json_encode(Auth::check());
      return view('pages.home', ['posts' => $data, 'tags' => $tags]);
    }

    public function post($id)
    {
      // $data = Post::with('author')->with('tags')->with('comments')->paginate(10);
      // $data = Post::find($id)->with('author')->with('tags')->with('comments');

      $data = Post::with('author')->with('tags')->with('comments')->find($id);
      $comments = $data->comments;
      
      
      $comments_data = [];
      foreach ($comments as $item) {
        $item = Comment::with('comment_author')->find($item->comment_id);

        $comments_data = array_merge($comments_data, [$item]);  
      }
      // return $comments_data;
      
      return view('pages.post', ['post' => $data, 'comments' => $comments_data]);
    }

    public function posts_with_tag($id)
    {
      $data = Post::with('author')->with('tags')->with('comments')
                  ->where('tag_id', $id)->paginate(10);
      
      return view('pages.tag', ['posts' => $data]);
    }
}