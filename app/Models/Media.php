<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Media extends Model
{
    use HasFactory;

    protected $table = 'media';
    public $timestamps = false;

    public function comments(){return $this->belongsToMany('App\Models\Comment');}

    public function posts(){return $this->belongsToMany('App\Models\Post');}
}
