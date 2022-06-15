@extends('layouts.app')
@section('content')
  <div style="margin: 50px">
    <div style="font-size: 48px; font-weight: 900; margin-bottom: -8px">{{ $post->title }}</div>
    <div style="border-left: 3px solid black; margin-bottom: 16px; padding-left: 10px">
      <div style="display: flex; margin-bottom: 5px">
        <div>by:</div>
        <a style="margin-left: 5px" href="/profile/{{ $post->author->user_id }}">{{ $post->author->username }}</a>
      </div>
  
      <div style="display: flex; align-items: center;
      justify-content: space-around; width: 100px">
          <a href="/profile/{{ $post->author->user_id }}">
            <img src='https://www.seekpng.com/png/detail/847-8474751_download-empty-profile.png' width='60'/>
          </a>
          <img src='https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Sort_up_font_awesome.svg/768px-Sort_up_font_awesome.svg.png'
          width='24' />{{ $post->votes }}
      </div>
    </div>

    <div style="border-left: 3px solid black; padding-left: 8px; margin-bottom: 24px; font-size: 20px">
        {{ $post->description }}</div>

    <div style="margin-bottom: 32px">-- 
      <a href="/profile/{{ $post->author->user_id }}">{{ $post->author->username }}</a>
       posted to
        {{ $post->tags->name }} on {{ $post->date }}</div>

    <form name="add-comment-form" id="add-comment-form" method="post" action="{{url('store-form')}}">
    <!-- CROSS Site Request Forgery Protection -->
        @csrf
       
        <div class="form-group">
          <textarea
            name="comment"
            class="form-control"
            required=""
            placeholder="Say something nice to {{ $post->author->username }}...">
          </textarea>
        </div>
        <button type="submit" class="btn btn-primary">Submit</button>
    </form>
      
    <div>
          <div>{{ count($post->comments) }} comments</div>
          @foreach ($post->comments as $index => $item)
          <div style="margin-top: 18px">
            <div style="display: flex">
              <div style="display: flex; align-items: center;
              justify-content: space-around; width: 100px">
                <a style="width: 50%" href="/profile/{{ $post->author->user_id }}">
                  <img src='https://www.seekpng.com/png/detail/847-8474751_download-empty-profile.png' width='40'/>
                </a>
                <img style="margin-left: 8px" src='https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Sort_up_font_awesome.svg/768px-Sort_up_font_awesome.svg.png'
                width='24' />{{ $item->votes }}
              </div>
              <div style="margin-left: 20px; padding-left: 20px; border-left: 2px solid black">
                <div style="font-size: 18px">{{ $item->description }}</div>
                <div style="display: flex; font-size: 14px">
                  <a href="/profile/{{ $post->author->user_id }}">
                    {{ $comments[$index]->comment_author->username }}
                  </a>

                  <div style="margin-left: 8px; margin-right: 8px">·</div>
                  <div>Date: {{ $item->date }}</div>
                </div>
              </div>
            </div>
          </div>
          @endforeach
    </div>
  
  </div>
@endsection