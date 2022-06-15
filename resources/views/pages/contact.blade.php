@extends('layouts.app')
@section('content')
  <div style="margin: 50px">
    <h1>Contact Us</h1>
    <hr>
    <!-- Content Row -->
    <div>
      <!-- Map Column -->
      <div>
        <!-- Embedded Google Map -->
        <iframe width="100%" height="400px" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="https://maps.google.com/maps?hl=en&amp;ie=UTF8&amp;ll=41.177967,-8.5960284&amp;t=m&amp;z=15&amp;output=embed"></iframe>
      </div>
      <!-- Contact Details Column -->
      <div>
        <h3 style="margin-top: 20px">Contact details</h3>
        <div class="row" style="color: black">
        <p style="margin-right: 40px">
          Faculdade de Engenharia (FEUP)<br>Rua Dr. Roberto Frias<br>4200-465 PORTO<br>
        </p>
        <p><i></i>
          <abbr title="Hours"></abbr> Monday - Sunday: 24h</p>
        </div>
        <div class="row" style="color: black">  
          <p style="margin-right: 40px">
            Diogo Moreira<br>up201804904@fc.up.pt
          </p>
          <p style="margin-right: 40px">
            Diogo Gomes<br>up201805367@edu.fc.up.pt
          </p>
          <p style="margin-right: 40px">
            Eduardo Ramos<br>up201906732@edu.fe.up.pt
          </p>
          <p>
            Dogukan Olgun<br>up202102204@edu.fe.up.pt
          </p>
        </div>
      </div>
    </div>
  </div>
@endsection