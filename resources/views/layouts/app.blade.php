<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- CSRF Token -->
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Laravel') }}</title>

    <!-- Styles -->
    <link href="{{ asset('css/milligram.min.css') }}" rel="stylesheet">
    <link href="{{ asset('css/app.css') }}" rel="stylesheet">
    <script type="text/javascript">
        // Fix for Firefox autofocus CSS bug
        // See: http://stackoverflow.com/questions/18943276/html-5-autofocus-messes-up-css-loading/18945951#18945951
    </script>
    <script type="text/javascript" src={{ asset('js/app.js') }} defer>
</script>
  </head>
  <body>
    <main>
      <header>
        <h1><a href="{{ url('/home') }}">Sportium!</a></h1>
        @if (Auth::check())
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <a class="nav-link" href="{{ URL::to('about') }}">About</a>
        <a class="nav-link" href="{{ URL::to('services') }}">Services</a>
        <a class="nav-link" href="{{ URL::to('faq') }}">FAQ</a> 
        <a class="nav-link" href="{{ URL::to('contact') }}">Contact</a>
        <a class="button" href="{{ url('/logout') }}"> Logout </a> <span>{{ Auth::user()->name }}</span>
        </nav>
        @else
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <a class="nav-link" href="{{ URL::to('about') }}">About</a>
        <a class="nav-link" href="{{ URL::to('services') }}">Services</a>
        <a class="nav-link" href="{{ URL::to('faq') }}">FAQ</a> 
        <a class="nav-link" href="{{ URL::to('contact') }}">Contact</a>
        <a class="authentication" href="{{ url('login') }}">Login</a>
        <a class="authentication" href="{{ url('register') }}">Register</a>
        </nav>
        @endif
      </header>
      <section id="content">
        @yield('content')
      </section>
    </main>
  </body>
</html>
