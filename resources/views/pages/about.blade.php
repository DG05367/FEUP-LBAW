@extends('layouts.app')
@section('content')
  <div style="margin: 50px">
    <h1>About</h1>
    <hr>
    <section>
      <div class="row">
        <div style="margin-right: 40px; color: black;">
          <h2>About Sportium</h2>
          <p>This is a news divulgation system available through the web for documenting sport news.</p>
          <p>Users can post news, comment on them, upvote or downvote and follow eachother.</p>
          <p>Users can also edit their own profiles.</p>
        </div>
        <div>
          <img src="img/res/about.jpg" alt="Sportium">
        </div>
      </div>
    </section>
    <section>
      <h2>Our Team</h2>
      <hr>
      <div class="row">
        <div style="width: 14rem; margin-right: 20px;">
          <img src="img/res/user.png" alt="Diogo Moreira">
          <div>
            <h5 style="color: black">Diogo Moreira</h5>
          </div>
        </div>

        <div style="width: 14rem; margin-right: 20px;">
          <img src="img/res/user.png" alt="Diogo Gomes">
          <div>
            <h5 style="color: black">Diogo Gomes</h5>
          </div>
        </div>

        <div style="width: 14rem; margin-right: 20px;">
          <img src="img/res/user.png" alt="Eduardo Ramos">
          <div>
            <h5 style="color: black">Eduardo Ramos</h5>
          </div>
        </div>

        <div style="width: 14rem; margin-right: 20px;">
          <img src="img/res/user.png" alt="Dogukan Olgun">
          <div>
            <h5 style="color: black">Dogukan Olgun</h5>
          </div>
        </div> 
      </div>     
    </section>
  </div>
@endsection