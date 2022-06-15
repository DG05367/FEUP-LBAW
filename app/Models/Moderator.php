<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Moderator extends Model
{
    use HasFactory;

    protected $table = 'moderator';
    public $timestamps = false;

    public function tag(){return $this->belongsTo('App\Models\Tag');}
}
