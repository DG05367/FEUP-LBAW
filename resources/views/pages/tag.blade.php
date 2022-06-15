@extends('layouts.app')

@section('content')
    <div style="margin: 50px">
        <div style="text-transform: capitalize; font-size: 54px; margin-left: 50px;
                padding-left: 30px; border-left: 3px solid black">
            {{ $posts[0]->tags->name }} posts   
        </div>
        @include('partials.posts')
    </div>
@endsection