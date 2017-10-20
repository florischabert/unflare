import os
import tarfile
import urllib
import glob
import random

MODEL = 'faster_rcnn_inception_resnet_v2_atrous_coco_11_06_2017'
SEED = 0

if not os.path.isdir(MODEL):
  print('Downloading %s...' % MODEL)
  opener = urllib.URLopener()
  opener.retrieve("http://storage.googleapis.com/download.tensorflow.org/models/object_detection/%s.tar.gz" % MODEL, "%s.tar.gz" % MODEL)
  tar = tarfile.open("%s.tar.gz" % MODEL)
  tar.extractall()
  tar.close()

if not os.path.exists('train.records') or not os.path.exists('eval.records'):
  print('Generating TF records...')
  images = glob.glob('../data/annotations/*.xml')
  random.seed(SEED)
  random.shuffle(images)
  eval_set, train_set = images[:len(images)/4], images[len(images)/4:]
  os.system('python pascal_to_tf.py %s train.records' % ' '.join(train_set))
  os.system('python pascal_to_tf.py %s eval.records' % ' '.join(eval_set))

print('Hydration done!')