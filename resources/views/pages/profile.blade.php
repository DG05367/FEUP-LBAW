@extends('layouts.app')
@section('content')
  <div style="margin: 50px">
    <div style="display: flex; border: 1px solid black">
        <img src='https://www.seekpng.com/png/detail/847-8474751_download-empty-profile.png' width='100'/>
        <div>
            <div style="display: flex; align-items: center">
                <div style="font-size: 22px; font-weight: bold; margin-left: 10px">@ {{ $profileData->username }}</div>
                <div style="margin-left: 10px; margin-right: 10px">·</div>
                <div style="font-size: 20px;">{{ $profileData->name }}</div>
                <div style="margin-left: 10px; margin-right: 10px">·</div>
                <button style="margin-top: 10px; font-size: 18px; margin-right: 10px">FOLLOW</button>
                <button style="margin-top: 10px; font-size: 18px; margin-right: 10px">REPORT</button>
            </div>
            <div style="margin-left: 10px">Email: {{ $profileData->email }}</div>
            <div style="display: flex; font-size: 18px">
                <div style="margin-left: 10px">{{ $profileData->location }}</div>
                <div style="margin-left: 10px; margin-right: 10px">·</div>
                <div>{{ $profileData->profile_description }}</div>
            </div>
        </div>
    </div>
    
    <div style="display: flex; margin-top: 10px;">
        <div style="width: 80%">
            <div style="border: 1px solid black">
                <div style="display: flex; margin-left: 10px; justify-content: space-between;
                    align-items: center; height: 60px; font-size: 24px">
                    <nav class="navbar nav-pills navbar-default">
                        @if ($tab == 'comments')
                            <a class="nav-link" href="{{ URL::to('profile/1/posts') }}">Posts</a>
                            <a class="nav-link" style="font-weight: bold; text-decoration: underline"
                                    href="{{ URL::to('profile/1/comments') }}">Comments</a>
                            <a class="nav-link" href="{{ URL::to('profile/1/likes') }}">Likes</a>
                        @elseif ($tab == 'likes')
                            <a class="nav-link" href="{{ URL::to('profile/1/posts') }}">Posts</a>
                            <a class="nav-link" href="{{ URL::to('profile/1/comments') }}">Comments</a>
                            <a class="nav-link" style="font-weight: bold; text-decoration: underline"
                                    href="{{ URL::to('profile/1/likes') }}">Likes</a>
                        @else
                            <a class="nav-link" style="font-weight: bold; text-decoration: underline"
                                    href="{{ URL::to('profile/1/posts') }}">Posts</a>
                            <a class="nav-link" href="{{ URL::to('profile/1/comments') }}">Comments</a>
                            <a class="nav-link" href="{{ URL::to('profile/1/likes') }}">Likes</a>
                        @endif 
                    </nav>                      
                </div>
            </div>
            @if ($tab == 'comments')
                @include('partials.profile.comments', ['comments' => $comments])
            @elseif ($tab == 'likes')
                @include('partials.profile.likes', ['posts' => $posts])
            @else
                @include('partials.profile.posts', ['posts' => $posts])
            @endif
            
        </div>
        <div style="margin-left: 10px; width: 20%">
            <div style="border: 1px solid black">
                <div style="font-size: 26px">Following <b>{{ count($profileData->following) }}</b></div>
                @foreach ($profileData->following as $follows)
                    <img src='https://www.seekpng.com/png/detail/847-8474751_download-empty-profile.png' width='40'/>
                @endforeach
            </div>
            <div style="border: 1px solid black; margin-top: 10px">
                <div style="font-size: 26px">Followers <b>{{ count($profileData->followers) }}</b></div>
                @foreach ($profileData->followers as $follower)
                    <img src='https://www.seekpng.com/png/detail/847-8474751_download-empty-profile.png' width='40'/>
                @endforeach
            </div>
        </div>
    </div> 
    
  </div>
@endsection