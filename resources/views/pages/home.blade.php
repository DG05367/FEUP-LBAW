@extends('layouts.app')
@section('content')
  <div style="margin: 50px">
    <h1>Welcome to Sportium!</h1>
    <hr>
    <section>    
    <div class="row">    
        <div style="margin-right: 80px">
              <div>
                <h4>
                  <i></i> Posts
                </h4>
              </div>
              <div style="color: black">
                <p>Posts are created by users detailing current news about sports.</p> 
            </div>
        </div> 
        <div style="margin-right: 80px">      
            <div>
                <h4>
                  <i"></i> Comments
                </h4>  
            </div>  
            <div style="color: black">    
            <p>You can comment on posts.</p>  
            </div>
        </div> 
        <div style="margin-right: 80px">       
            <div>    
                <h4>
                  <i"></i> Easy to use
                </h4>  
            </div> 
            <div style="color: black">    
                <p>Easy to see the current hottest news.</p>      
            </div>    
        </div>  
    </div>
    </section>
    <div style='display: flex; margin-left: 30px; margin-top: 10px'>
      @foreach ($tags as $item)
        <a style="display:flex; align-items: center; justify-content: center;
        height: 200px; width: 300px; border: 1px solid black;
        font-size: 38px; margin-left: 20px"
        href="/tag/{{ $item->tag_id }}">{{ $item->name }}</a>
      @endforeach
    </div>
    @include('partials.posts')
    <section>
      <h2>Sportium Features</h2>
      <hr>
      <div class="row">
        <div style="color: black; margin-right: 150px;">
          <p>The Sportium includes:</p>
          <ul>
            <li>Search</li>
            <li>Posts</li>
            <li>Comment</li>
          </ul>
        </div>
        <div>
          <img class="row" src="img/res/index.png" alt="Sportium">
        </div>
      </div>
    </section>
  </div>
@endsection