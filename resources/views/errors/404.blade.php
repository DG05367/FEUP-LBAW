@extends('layouts.app')
@section('content')
  <div class="container">
    <h1>404 <span style="color: black">Page not found</span></h1>
    <hr>
    <div class="row">
      <div>
        <div>
          <p style="font-size: 50px">The page you're looking for could not be found.</p>
          <p>
            <a href="{{ URL::to('/') }}" role="button" style="font-size: 20px">Go to home page.</a>
          </p>
        </div>
      </div>
    </div>
@endsection