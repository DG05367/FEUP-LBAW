<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReportComment extends Model
{
    use HasFactory;

    protected $table = 'report_comment';
    public $timestamps = false;

    public function reporter_comment(){return $this->belongsTo('App\Models\User');}

    public function reported_comment(){return $this->belongsTo('App\Models\Comment');}
}
