#!/usr/bin/python
'''Read from PyMongo, make simple model and export for CoreML'''

# make this work nice when support for python 3 releases
# from __future__ import print_function # python 3 is good to go!!!

# database imports
from pymongo import MongoClient
from pymongo.errors import ServerSelectionTimeoutError

# model imports
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import Pipeline

from sklearn.preprocessing import StandardScaler

import numpy as np

# export 
import coremltools


dsid = 9
client  = MongoClient(serverSelectionTimeoutMS=50)
db = client.sklearndatabase


# create feature/label vectors from database
X=[];
y=[];
for a in db.labeledinstances.find({"dsid":dsid}): 
    X.append([float(val) for val in a['feature']])
    y.append(a['label'])    


print("Found",len(y),"labels and",len(X),"feature vectors")
print("Unique classes found:",np.unique(y))

clf = RandomForestClassifier(n_estimators=150)
clf_svm = SVC(kernel="rbf")
clf_pipe = Pipeline([("SCL", StandardScaler()),
	("SVC",SVC())])

clf_knn = KNeighborsClassifier(n_neighbors=1)

print("Training Model", clf)

clf.fit(X,y)
clf_svm.fit(X,y)
clf_pipe.fit(X,y)
clf_knn.fit(X,y)

predict_thing = clf_knn.predict(X)
print(predict_thing)

print("Exporting to CoreML")

coreml_model = coremltools.converters.sklearn.convert(
	clf) 

# save out as a file
coreml_model.save('RandomForestAccel9.mlmodel')


coreml_model = coremltools.converters.sklearn.convert(
	clf_svm) 

# save out as a file
coreml_model.save('SVMAccel9.mlmodel')

coreml_model = coremltools.converters.sklearn.convert(
	clf_pipe) 

# save out as a file
coreml_model.save('PipeAccel9.mlmodel')


coreml_model = coremltools.converters.sklearn.convert(
	clf_knn)

# save out as a file
coreml_model.save('KnnAccel9.mlmodel')

# close the mongo connection

client.close() 





