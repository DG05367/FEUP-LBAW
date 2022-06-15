<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReportPost extends Model
{
    use HasFactory;

    protected $table = 'report_post';
    public $timestamps = false;

    public function reporter(){return $this->belongsTo('App\Models\User');}

    public function post(){return $this->belongsTo('App\Models\Post');}
}
